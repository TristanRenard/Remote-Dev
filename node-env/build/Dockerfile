FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    # Essentiels
    curl \
    git \
    wget \
    unzip \
    htop \
    sudo \
    vim \
    neovim \
    ca-certificates \
    gnupg \
    lsb-release \
    openssh-client \
    locales \
    # Build essentials
    build-essential \
    python3 \
    python3-pip \
    # Utilitaires
    jq \
    tree \
    ripgrep \
    fd-find \
    bat \
    fzf \
    tmux \
    zsh \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Node.js LTS (22.x)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g typescript ts-node pnpm yarn tsx nodemon \
    && rm -rf /var/lib/apt/lists/*

# Go
RUN curl -fsSL https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | tar -C /usr/local -xzf -

# Rust
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH="/usr/local/cargo/bin:/usr/local/go/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

# Utilisateur
ARG USER=coder
RUN useradd --uid 10000 --groups sudo --no-create-home --shell /bin/bash ${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR /home/${USER}

ENV PATH="/usr/local/go/bin:/usr/local/cargo/bin:${PATH}"