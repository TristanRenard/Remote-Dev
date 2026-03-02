terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

provider "coder" {}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# Paramètres affichés à la création du workspace
variable "dotfiles_uri" {
  description = "URL d'un repo dotfiles à cloner (laisser vide pour ignorer)"
  default     = ""
}

# code-server (VS Code dans le navigateur)
resource "coder_app" "code_server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code"
  url          = "http://localhost:8080/?folder=/home/coder"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:8080/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  startup_script = <<-EOT
    set -e

    # code-server
    if ! command -v code-server &>/dev/null; then
      curl -fsSL https://code-server.dev/install.sh | sh
    fi
    code-server --auth none --port 8080 &

    # dotfiles
    if [ -n "${var.dotfiles_uri}" ]; then
      coder dotfiles -y "${var.dotfiles_uri}"
    fi

    # Node.js via nvm
    if ! command -v nvm &>/dev/null; then
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
      export NVM_DIR="$HOME/.nvm"
      source "$NVM_DIR/nvm.sh"
      nvm install --lts
      nvm use --lts
      npm install -g typescript ts-node pnpm
    fi
  EOT

  metadata {
    display_name = "CPU"
    key          = "cpu"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM"
    key          = "ram"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Disk"
    key          = "disk"
    script       = "coder stat disk"
    interval     = 60
    timeout      = 1
  }
}

# Image Docker avec Docker-in-Docker
resource "docker_image" "node_env" {
  name = "node-env-coder"
  build {
    context = "${path.module}/build"
  }
  triggers = {
    dockerfile = filemd5("${path.module}/build/Dockerfile")
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.node_env.image_id
  name  = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"

  # Docker-in-Docker
  privileged = true

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
  ]

  command = [
    "sh", "-c",
    <<-EOT
      # Démarrer le daemon Docker
      dockerd &
      # Démarrer l'agent Coder
      exec /usr/bin/coder agent
    EOT
  ]

  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home.name
    read_only      = false
  }

  volumes {
    container_path = "/var/lib/docker"
    volume_name    = docker_volume.docker_data.name
    read_only      = false
  }

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
}

# Volume persistant pour le home
resource "docker_volume" "home" {
  name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}-home"
  lifecycle {
    ignore_changes = all
  }
}

# Volume persistant pour les images Docker (DinD)
resource "docker_volume" "docker_data" {
  name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}-docker"
  lifecycle {
    ignore_changes = all
  }
}
