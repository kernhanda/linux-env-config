#!/usr/bin/env bash

# This script installs most relevant packages for Ubuntu 22.04.
_has() {
  # shellcheck disable=SC2046 # Quoting everything gives the wrong semantics.
  return $(which "$1" >/dev/null)
}

sudo apt install -y \
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

if ! _has nvim; then
  wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
  chmod +x nvim.appimage
  ./nvim.appimage --appimage-extract
  sudo mv squashfs-root /
  sudo ln -s /squashfs-root/AppRun /usr/bin/nvim
  rm nvim.appimage
fi

if ! _has eza; then
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
fi

if ! _has fd; then
  mkdir -p ~/.local/bin
  ln -s "$(which fdfind)" ~/.local/bin/fd
fi

if ! _has zoxide; then
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

if ! _has lazygit; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    install lazygit "$HOME"/.local/bin
    rm -r lazygit lazygit.tar.gz
fi
