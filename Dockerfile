FROM ubuntu:latest

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt update && apt install -y \
  bat \
  build-essential \
  clang-15 \
  curl \
  fd-find \
  git \
  gpg \
  libssl-dev \
  pkg-config \
  python3 \
  python3-pip \
  python3-venv \
  ripgrep \
  sudo \
  tmux \
  tree \
  unzip \
  vim \
  wget \
  zsh \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Install Neovim AppImage.
RUN wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage \
  && chmod +x nvim.appimage \
  && ./nvim.appimage --appimage-extract \
  && mv squashfs-root / \
  && ln -s /squashfs-root/AppRun /usr/bin/nvim \
  && rm nvim.appimage

# Install eza via apt.
RUN mkdir -p /etc/apt/keyrings \
  && wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list \
  && chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list \
  && apt update \
  && apt install -y eza

# Create a user with sudo privileges.
ARG USER=kern
RUN useradd -rm -d /home/${USER} -s $(which zsh) -g root -G sudo ${USER}
RUN chown -R ${USER} /home/${USER}
RUN echo "${USER} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER}

# Copy over dotfiles and switch to the non-root user.
COPY . /home/${USER}/.dotfiles
RUN chown -R ${USER} /home/${USER}
USER ${USER}

# Install the dotfiles.
WORKDIR /home/${USER}/.dotfiles
RUN ./install.sh -t build

# Symlink fd, since the actual binary name is fdfind.
RUN mkdir -p ~/.local/bin
RUN ln -s $(which fdfind) ~/.local/bin/fd

# Install zoxide. (This needs to be done for the local, non-root user.)
RUN curl -sSf https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash -u --

# Needs to be fully qualified
ENV NVM_DIR /home/${USER}/.nvm
ENV NODE_VERSION 20.13.1

# Install nvm with node and npm
RUN curl -sSf https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash -s --

RUN \. $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/v$NODE_VERSION/bin:$PATH

# Install gitstatusd.
RUN /home/${USER}/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/home/${USER}/.cargo/bin:${PATH}"

RUN cargo install tree-sitter-cli && rustup component add rustfmt

# Install Neovim plugins.
RUN nvim --headless "+Lazy! sync" "+MasonToolsUpdateSync" +qa

# Install vim plugins.
RUN vim +PlugInstall +qa

WORKDIR /home/${USER}
ENTRYPOINT zsh
