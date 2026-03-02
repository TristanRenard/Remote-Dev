FROM ubuntu:24.04

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV NVM_DIR=/home/coder/.nvm

# Dépendances système
RUN apt-get update && apt-get install -y \
  curl \
  git \
  wget \
  unzip \
  htop \
  sudo \
  ca-certificates \
  gnupg \
  lsb-release \
  openssh-client \
  locales \
  && locale-gen en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*

# Docker CLI + daemon (pour Docker-in-Docker)
RUN install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && chmod a+r /etc/apt/keyrings/docker.gpg \
  && echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update \
  && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
  && rm -rf /var/lib/apt/lists/*

# Coder agent
RUN curl -fsSL https://coder.com/install.sh | sh

# Utilisateur coder
RUN id -u coder &>/dev/null || useradd -m -s /bin/bash coder \
  && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
  && usermod -aG docker coder

USER coder
WORKDIR /home/coder

# nvm + Node.js LTS + outils globaux
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
  && source "$NVM_DIR/nvm.sh" \
  && nvm install --lts \
  && nvm use --lts \
  && nvm alias default node \
  && npm install -g typescript ts-node pnpm

# Ajouter nvm au bashrc
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc \
  && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc \
  && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc

USER root