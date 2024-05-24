# syntax=docker/dockerfile:1
FROM ubuntu:latest

RUN apt update && apt install -y \
  bat \
  build-essential \
  curl \
  fd-find \
  git \
  gpg \
  ripgrep \
  sudo \
  tmux \
  tree \
  unzip \
  vim \
  wget \
  zsh

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
RUN curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# Install gitstatusd.
RUN /home/${USER}/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install

# Install Neovim plugins.
RUN nvim --headless "+Lazy! sync" +qa

# Install vim plugins.
RUN vim +PlugInstall +qa

WORKDIR /home/${USER}
ENTRYPOINT zsh
