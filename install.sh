#!/usr/bin/env bash

# Dotfiles installation script using GNU Stow.
# Usage: ./install.sh [options] [packages...]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"

# Package definitions
PACKAGES_ALL=(zsh tmux vim git gh nvim ripgrep editorconfig claude coder go)
PACKAGES_MINIMAL=(zsh vim git)

# Default to all packages
PACKAGES=("${PACKAGES_ALL[@]}")

# Verbose logging (off by default)
VERBOSE=false

usage() {
  cat <<EOF
Usage: $0 [OPTIONS] [PACKAGES...]

Install dotfiles using GNU Stow.

OPTIONS:
  -h, --help      Show this help message
  -l, --list      List available packages
  -a, --all       Install all packages (default)
  -r, --remove    Remove (unstow) packages
  -n, --no-omz    Skip oh-my-zsh installation
  -v, --verbose   Show detailed logging output
  --minimal       Install minimal profile (zsh, vim, git)
  --full          Install full profile (all packages, default)
  --shellcheck    Lint all shell scripts

PROFILES:
  minimal: ${PACKAGES_MINIMAL[*]}
  full:    ${PACKAGES_ALL[*]}

PACKAGES:
  ${PACKAGES_ALL[*]}

If no packages specified, the full profile will be installed.

EXAMPLES:
  $0                    # Install all packages (full profile)
  $0 --minimal          # Install minimal profile
  $0 zsh nvim           # Install only zsh and nvim
  $0 -r zsh             # Remove zsh package
  $0 --no-omz           # Install all but skip oh-my-zsh setup
EOF
}

print_success() {
  printf "\e[0;32m  [✔] %s\e[0m\n" "$1"
}

print_error() {
  printf "\e[0;31m  [✖] %s\e[0m\n" "$1"
}

print_info() {
  printf "\e[0;34m  [i] %s\e[0m\n" "$1"
}

log_verbose() {
  if [[ "${VERBOSE}" == true ]]; then
    printf "\e[0;90m      %s\e[0m\n" "$1"
  fi
}

detect_pkg_manager() {
  if command -v apt &>/dev/null; then
    echo "apt"
  elif command -v brew &>/dev/null; then
    echo "brew"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  else
    echo ""
  fi
}

install_stow() {
  print_info "Installing GNU Stow..."

  local mgr
  mgr=$(detect_pkg_manager)
  log_verbose "Detected package manager: ${mgr:-none}"

  if [[ "${mgr}" == "apt" ]]; then
    log_verbose "Running: sudo apt update && sudo apt install -y stow"
    sudo apt update && sudo apt install -y stow
  elif [[ "${mgr}" == "brew" ]]; then
    log_verbose "Running: brew install stow"
    brew install stow
  elif [[ "${mgr}" == "pacman" ]]; then
    log_verbose "Running: sudo pacman -S --noconfirm stow"
    sudo pacman -S --noconfirm stow
  elif [[ "${mgr}" == "dnf" ]]; then
    log_verbose "Running: sudo dnf install -y stow"
    sudo dnf install -y stow
  else
    print_error "Could not detect package manager. Install stow manually."
    exit 1
  fi

  if command -v stow &>/dev/null; then
    log_verbose "stow binary: $(command -v stow)"
    print_success "Installed stow"
  else
    print_error "Failed to install stow"
    exit 1
  fi
}

check_stow() {
  if ! command -v stow &>/dev/null; then
    log_verbose "stow not found in PATH, installing..."
    install_stow
  else
    log_verbose "stow already available: $(command -v stow)"
  fi
}

pkg_install() {
  local pkg=$1
  local mgr
  mgr=$(detect_pkg_manager)
  log_verbose "Installing system package '${pkg}' via ${mgr:-unknown}"

  if [[ "${mgr}" == "apt" ]]; then
    sudo apt update -qq && sudo apt install -y "$pkg"
  elif [[ "${mgr}" == "brew" ]]; then
    brew install "$pkg"
  elif [[ "${mgr}" == "pacman" ]]; then
    sudo pacman -S --noconfirm "$pkg"
  elif [[ "${mgr}" == "dnf" ]]; then
    sudo dnf install -y "$pkg"
  else
    print_error "Could not detect package manager. Install ${pkg} manually."
    return 1
  fi
}

install_make() {
  if command -v make &>/dev/null; then
    print_info "make already installed: $(make --version | head -1)"
    return 0
  fi

  print_info "Installing make..."
  pkg_install make

  if command -v make &>/dev/null; then
    print_success "Installed $(make --version | head -1)"
  else
    print_error "Failed to install make"
    return 1
  fi
}

install_tmux() {
  if command -v tmux &>/dev/null; then
    print_info "tmux already installed: $(tmux -V)"
    return 0
  fi

  print_info "Installing tmux..."
  pkg_install tmux

  if command -v tmux &>/dev/null; then
    print_success "Installed $(tmux -V)"
  else
    print_error "Failed to install tmux"
    return 1
  fi
}

install_ripgrep() {
  if command -v rg &>/dev/null; then
    print_info "ripgrep already installed: $(rg --version | head -1)"
    return 0
  fi

  print_info "Installing ripgrep..."
  pkg_install ripgrep

  if command -v rg &>/dev/null; then
    print_success "Installed $(rg --version | head -1)"
  else
    print_error "Failed to install ripgrep"
    return 1
  fi
}

install_omz() {
  print_info "Setting up oh-my-zsh..."

  ZSH="${HOME}/.oh-my-zsh"
  ZSH_CUSTOM="${ZSH_CUSTOM:-${ZSH}/custom}"

  # Clone or update Oh My Zsh.
  log_verbose "ZSH dir: ${ZSH}"
  log_verbose "ZSH_CUSTOM dir: ${ZSH_CUSTOM}"
  if [[ ! -d "${ZSH}" ]]; then
    log_verbose "Cloning oh-my-zsh into ${ZSH}"
    git clone --quiet --filter=blob:none https://github.com/robbyrussell/oh-my-zsh "${ZSH}"
    print_success "Installed oh-my-zsh"
  else
    log_verbose "Updating existing oh-my-zsh at ${ZSH}"
    git -C "${ZSH}" pull --quiet
    print_success "Updated oh-my-zsh"
  fi

  # Clone or update Powerlevel10k.
  THEME_REPO_URL="https://github.com/romkatv/powerlevel10k"
  THEME_PATH="${ZSH_CUSTOM}/themes/${THEME_REPO_URL##*/}"
  THEME_VERSION_TAG="master"
  if command -v jq &>/dev/null; then
    THEME_VERSION_TAG=$(curl -s https://api.github.com/repos/romkatv/powerlevel10k/releases/latest | jq -r .tag_name)
  fi
  log_verbose "Powerlevel10k version: ${THEME_VERSION_TAG}, path: ${THEME_PATH}"
  if [[ ! -d "${THEME_PATH}" ]]; then
    log_verbose "Cloning powerlevel10k from ${THEME_REPO_URL}"
    git clone --quiet --filter=blob:none --branch "${THEME_VERSION_TAG}" "${THEME_REPO_URL}" "${THEME_PATH}"
    print_success "Installed powerlevel10k"
  else
    log_verbose "Updating existing powerlevel10k at ${THEME_PATH}"
    git -C "${THEME_PATH}" fetch --quiet
    git -C "${THEME_PATH}" checkout "${THEME_VERSION_TAG}" --quiet
    print_success "Updated powerlevel10k"
  fi

  # Install or update custom oh-my-zsh plugins.
  CUSTOM_PLUGIN_REPOS=(
    "https://github.com/Aloxaf/fzf-tab"
    "https://github.com/zdharma-continuum/fast-syntax-highlighting"
    "https://github.com/zsh-users/zsh-autosuggestions"
  )
  for REPO_URL in "${CUSTOM_PLUGIN_REPOS[@]}"; do
    PLUGIN_NAME="${REPO_URL##*/}"
    PLUGIN_PATH="${ZSH_CUSTOM}/plugins/${PLUGIN_NAME}"
    log_verbose "Plugin ${PLUGIN_NAME}: repo=${REPO_URL} path=${PLUGIN_PATH}"
    if [[ ! -d "${PLUGIN_PATH}" ]]; then
      log_verbose "Cloning ${PLUGIN_NAME} into ${PLUGIN_PATH}"
      git clone --quiet --filter=blob:none "${REPO_URL}" "${PLUGIN_PATH}"
      print_success "Installed plugin: ${PLUGIN_NAME}"
    else
      log_verbose "Pulling latest for ${PLUGIN_NAME}"
      git -C "${PLUGIN_PATH}" pull --quiet
      print_success "Updated plugin: ${PLUGIN_NAME}"
    fi
  done
}

install_fd() {
  if command -v fd &>/dev/null; then
    print_info "fd already installed: $(fd --version)"
    return 0
  fi

  print_info "Installing fd..."

  local version
  version=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
  local url="https://github.com/sharkdp/fd/releases/download/v${version}/fd-v${version}-x86_64-unknown-linux-gnu.tar.gz"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  log_verbose "fd version: ${version}"
  log_verbose "Download URL: ${url}"
  log_verbose "Temp dir: ${tmp_dir}"

  if curl -fsSL "${url}" -o "${tmp_dir}/fd.tar.gz"; then
    tar -xzf "${tmp_dir}/fd.tar.gz" -C "${tmp_dir}" --strip-components=1
    sudo mv "${tmp_dir}/fd" /usr/local/bin/fd
    rm -rf "${tmp_dir}"
    print_success "Installed fd $(fd --version)"
  else
    rm -rf "${tmp_dir}"
    print_error "Failed to download fd"
    return 1
  fi
}

install_bat() {
  if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
    print_info "bat already installed"
    return 0
  fi

  print_info "Installing bat..."

  local version
  version=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
  local url="https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-x86_64-unknown-linux-gnu.tar.gz"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  log_verbose "bat version: ${version}"
  log_verbose "Download URL: ${url}"
  log_verbose "Temp dir: ${tmp_dir}"

  if curl -fsSL "${url}" -o "${tmp_dir}/bat.tar.gz"; then
    tar -xzf "${tmp_dir}/bat.tar.gz" -C "${tmp_dir}" --strip-components=1
    sudo mv "${tmp_dir}/bat" /usr/local/bin/bat
    rm -rf "${tmp_dir}"
    print_success "Installed bat $(bat --version)"
  else
    rm -rf "${tmp_dir}"
    print_error "Failed to download bat"
    return 1
  fi
}

install_lazygit() {
  if command -v lazygit &>/dev/null; then
    print_info "lazygit already installed: $(lazygit --version | head -1)"
    return 0
  fi

  print_info "Installing lazygit..."

  local version
  version=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
  local url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  log_verbose "lazygit version: ${version}"
  log_verbose "Download URL: ${url}"
  log_verbose "Temp dir: ${tmp_dir}"

  if curl -fsSL "${url}" -o "${tmp_dir}/lazygit.tar.gz"; then
    tar -xzf "${tmp_dir}/lazygit.tar.gz" -C "${tmp_dir}"
    sudo mv "${tmp_dir}/lazygit" /usr/local/bin/lazygit
    rm -rf "${tmp_dir}"
    print_success "Installed lazygit $(lazygit --version | head -1)"
  else
    rm -rf "${tmp_dir}"
    print_error "Failed to download lazygit"
    return 1
  fi
}

install_gh() {
  if command -v gh &>/dev/null; then
    print_info "gh already installed: $(gh --version | head -1)"
    return 0
  fi

  print_info "Installing GitHub CLI (gh)..."

  local mgr
  mgr=$(detect_pkg_manager)
  log_verbose "Detected package manager: ${mgr:-none}"

  if [[ "${mgr}" == "brew" ]]; then
    brew install gh
  elif [[ "${mgr}" == "apt" ]]; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update && sudo apt install -y gh
  elif [[ "${mgr}" == "pacman" ]]; then
    sudo pacman -S --noconfirm github-cli
  elif [[ "${mgr}" == "dnf" ]]; then
    sudo dnf install -y gh
  else
    print_error "Could not detect package manager. Install gh manually: https://cli.github.com"
    return 1
  fi

  if command -v gh &>/dev/null; then
    print_success "Installed $(gh --version | head -1)"
  else
    print_error "Failed to install gh"
    return 1
  fi
}

install_yq() {
  if command -v yq &>/dev/null; then
    print_info "yq already installed: $(yq --version)"
    return 0
  fi

  print_info "Installing yq..."

  local version
  version=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
  local url="https://github.com/mikefarah/yq/releases/download/v${version}/yq_linux_amd64"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  log_verbose "yq version: ${version}"
  log_verbose "Download URL: ${url}"
  log_verbose "Temp dir: ${tmp_dir}"

  if curl -fsSL "${url}" -o "${tmp_dir}/yq"; then
    chmod +x "${tmp_dir}/yq"
    sudo mv "${tmp_dir}/yq" /usr/local/bin/yq
    rm -rf "${tmp_dir}"
    print_success "Installed yq $(yq --version)"
  else
    rm -rf "${tmp_dir}"
    print_error "Failed to download yq"
    return 1
  fi
}

install_go() {
  if command -v go &>/dev/null; then
    print_info "Go already installed: $(go version)"
    return 0
  fi

  print_info "Installing Go..."

  local version
  version=$(curl -s https://go.dev/dl/?mode=json | grep -oP '"version":\s*"go\K[0-9.]+' | head -1)
  if [[ -z "${version}" ]]; then
    # Fallback if API parsing fails
    version="1.24.1"
    log_verbose "API parsing failed, using fallback version: ${version}"
  fi
  local url="https://go.dev/dl/go${version}.linux-amd64.tar.gz"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  log_verbose "Go version: ${version}"
  log_verbose "Download URL: ${url}"
  log_verbose "Temp dir: ${tmp_dir}"

  if curl -fsSL "${url}" -o "${tmp_dir}/go.tar.gz"; then
    log_verbose "Removing existing /usr/local/go"
    sudo rm -rf /usr/local/go
    log_verbose "Extracting Go to /usr/local"
    sudo tar -C /usr/local -xzf "${tmp_dir}/go.tar.gz"
    rm -rf "${tmp_dir}"
    # Symlink into a PATH location so it's available immediately
    log_verbose "Creating symlinks in /usr/local/bin"
    sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
    sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
    print_success "Installed Go $(/usr/local/go/bin/go version)"
  else
    rm -rf "${tmp_dir}"
    print_error "Failed to download Go"
    return 1
  fi
}

install_eza() {
  if command -v eza &>/dev/null; then
    print_info "eza already installed: $(eza --version | head -1)"
    return 0
  fi

  print_info "Installing eza..."

  local latest_url="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  log_verbose "Download URL: ${latest_url}"
  log_verbose "Temp dir: ${tmp_dir}"

  if curl -fsSL "${latest_url}" -o "${tmp_dir}/eza.tar.gz"; then
    tar -xzf "${tmp_dir}/eza.tar.gz" -C "${tmp_dir}"
    sudo mv "${tmp_dir}/eza" /usr/local/bin/eza
    rm -rf "${tmp_dir}"
    print_success "Installed eza $(eza --version | head -1)"
  else
    rm -rf "${tmp_dir}"
    print_error "Failed to download eza"
    return 1
  fi
}

install_fzf() {
  print_info "Setting up fzf..."

  FZF_DIR="${HOME}/.fzf"
  log_verbose "fzf dir: ${FZF_DIR}"

  if [[ ! -d "${FZF_DIR}" ]]; then
    log_verbose "Cloning fzf into ${FZF_DIR}"
    git clone --quiet --depth 1 https://github.com/junegunn/fzf.git "${FZF_DIR}"
    print_success "Cloned fzf"
  else
    log_verbose "Pulling latest fzf"
    git -C "${FZF_DIR}" pull --quiet
    print_success "Updated fzf"
  fi

  # Install fzf binary and shell integrations (non-interactively)
  log_verbose "Running fzf installer: ${FZF_DIR}/install --bin --no-bash --no-zsh --no-fish"
  "${FZF_DIR}/install" --bin --no-bash --no-zsh --no-fish >/dev/null 2>&1
  print_success "Installed fzf binary"
}

install_nvim() {
  print_info "Installing latest Neovim..."

  if command -v nvim &>/dev/null; then
    local current_version
    current_version=$(nvim --version | head -1 | grep -oP 'v\K[0-9.]+')
    print_info "Current Neovim version: ${current_version}"
  fi

  local latest_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
  local tmp_dir
  tmp_dir=$(mktemp -d)
  log_verbose "Download URL: ${latest_url}"
  log_verbose "Temp dir: ${tmp_dir}"

  if curl -fsSL "${latest_url}" -o "${tmp_dir}/nvim.tar.gz"; then
    log_verbose "Extracting Neovim archive"
    tar -xzf "${tmp_dir}/nvim.tar.gz" -C "${tmp_dir}"
    log_verbose "Installing to /opt/nvim"
    sudo rm -rf /opt/nvim
    sudo mv "${tmp_dir}/nvim-linux-x86_64" /opt/nvim
    # Create symlink if not already on PATH via /opt/nvim/bin
    log_verbose "Creating symlink: /usr/local/bin/nvim -> /opt/nvim/bin/nvim"
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm -rf "${tmp_dir}"
    print_success "Installed Neovim $(nvim --version | head -1)"
  else
    rm -rf "${tmp_dir}"
    print_error "Failed to download Neovim"
    return 1
  fi
}

install_node() {
  local need_install=false

  if ! command -v node &>/dev/null; then
    need_install=true
  else
    local node_major
    node_major=$(node -v | grep -oP 'v\K[0-9]+')
    if (( node_major < 18 )); then
      print_info "Node.js v${node_major} is too old (need >= 18), upgrading..."
      need_install=true
    elif ! npm --version &>/dev/null; then
      print_info "Node.js $(node -v) found but npm is broken, reinstalling..."
      need_install=true
    else
      print_info "Node.js already installed: $(node -v), npm: $(npm --version)"
      return 0
    fi
  fi

  if [[ "${need_install}" == true ]]; then
    print_info "Installing Node.js LTS..."

    local mgr
    mgr=$(detect_pkg_manager)
    log_verbose "Detected package manager: ${mgr:-none}"

    if [[ "${mgr}" == "apt" ]]; then
      # Purge all existing Node.js / npm packages to avoid version conflicts
      log_verbose "Purging existing Node.js and npm packages"
      sudo apt purge -y nodejs npm libnode-dev libnode72 nodejs-doc 2>/dev/null || true
      sudo apt autoremove -y 2>/dev/null || true
      # Remove stale distro npm that can conflict with NodeSource
      if [[ -d /usr/share/nodejs/npm ]]; then
        log_verbose "Removing stale /usr/share/nodejs/npm"
        sudo rm -rf /usr/share/nodejs/npm
      fi
      log_verbose "Adding NodeSource LTS repository"
      curl -fsSL "https://deb.nodesource.com/setup_lts.x" | sudo -E bash -
      sudo apt install -y nodejs
    elif [[ "${mgr}" == "brew" ]]; then
      brew install node
    elif [[ "${mgr}" == "pacman" ]]; then
      sudo pacman -S --noconfirm nodejs npm
    elif [[ "${mgr}" == "dnf" ]]; then
      sudo dnf install -y nodejs npm
    else
      print_error "Could not detect package manager. Install Node.js LTS manually."
      return 1
    fi

    if command -v node &>/dev/null && npm --version &>/dev/null; then
      print_success "Installed Node.js $(node -v) with npm $(npm --version)"
    else
      print_error "Failed to install Node.js"
      return 1
    fi
  fi
}

install_claude_code() {
  print_info "Installing Claude Code..."

  install_node

  log_verbose "Running: sudo npm install -g @anthropic-ai/claude-code@latest"
  sudo npm install -g @anthropic-ai/claude-code@latest
  if command -v claude &>/dev/null; then
    print_success "Installed Claude Code $(claude --version 2>/dev/null || echo '')"
    claude install
    print_success "Completed Claude Code setup"
  else
    print_error "Failed to install Claude Code"
    return 1
  fi
}

install_coder() {
  print_info "Installing Coder CLI..."

  log_verbose "Running: curl -fsSL https://coder.com/install.sh | sh"
  curl -fsSL https://coder.com/install.sh | sh
  if command -v coder &>/dev/null; then
    print_success "Installed Coder CLI $(coder version 2>/dev/null | head -1 || echo '')"
  else
    print_error "Failed to install Coder CLI"
    return 1
  fi
}

install_tpm() {
  print_info "Setting up TPM (Tmux Plugin Manager)..."

  TPM_DIR="${HOME}/.tmux/plugins/tpm"
  log_verbose "TPM dir: ${TPM_DIR}"

  if [[ ! -d "${TPM_DIR}" ]]; then
    log_verbose "Cloning TPM into ${TPM_DIR}"
    mkdir -p "${HOME}/.tmux/plugins"
    git clone --quiet --filter=blob:none https://github.com/tmux-plugins/tpm "${TPM_DIR}"
    print_success "Installed TPM"
  else
    git -C "${TPM_DIR}" pull --quiet
    print_success "Updated TPM"
  fi

  # Install plugins automatically (runs outside tmux)
  print_info "Installing tmux plugins..."
  "${TPM_DIR}/bin/install_plugins"
  print_success "Installed tmux plugins"
}

stow_package() {
  local package=$1
  local action=$2

  log_verbose "stow_package: package=${package} action=${action}"

  if [[ ! -d "${DOTFILES_DIR}/${package}" ]]; then
    log_verbose "No dotfiles directory for ${package}, skipping stow"
    return 0
  fi

  # Ensure ~/.config exists for packages that need it
  if [[ -d "${DOTFILES_DIR}/${package}/.config" ]]; then
    log_verbose "Creating ${HOME}/.config (needed by ${package})"
    mkdir -p "${HOME}/.config"
  fi

  if [[ "${action}" == "remove" ]]; then
    log_verbose "Running: stow -d ${DOTFILES_DIR} -t ${HOME} -D ${package}"
    stow -d "${DOTFILES_DIR}" -t "${HOME}" -D "${package}" 2>/dev/null && \
      print_success "Removed ${package}" || \
      print_info "Package ${package} was not stowed"
  else
    # Remove foreign symlinks that would conflict with stow (files and directories)
    while IFS= read -r rel_path; do
      local target="${HOME}/${rel_path}"
      if [[ -L "${target}" ]] && [[ "$(readlink "${target}")" != *"${DOTFILES_DIR}/${package}/"* ]]; then
        rm "${target}"
        print_info "Removed conflicting symlink: ${rel_path}"
      fi
    done < <(cd "${DOTFILES_DIR}/${package}" && find . \( -type f -o -type d \) ! -name . -printf '%P\n')

    # Use --adopt to handle existing files, then restore from git
    log_verbose "Running: stow -d ${DOTFILES_DIR} -t ${HOME} --restow --adopt ${package}"
    if stow -d "${DOTFILES_DIR}" -t "${HOME}" --restow --adopt "${package}" 2>/dev/null; then
      # Restore any adopted files to our version
      log_verbose "Restoring adopted files from git"
      git -C "${SCRIPT_DIR}" checkout -- "${DOTFILES_DIR}/${package}" 2>/dev/null || true
      print_success "Installed ${package}"
    else
      print_error "Failed to install ${package}"
      return 1
    fi
  fi
}

list_packages() {
  echo "Available packages:"
  for pkg in "${PACKAGES_ALL[@]}"; do
    if [[ -d "${DOTFILES_DIR}/${pkg}" ]]; then
      local marker=""
      # Mark minimal packages
      for min_pkg in "${PACKAGES_MINIMAL[@]}"; do
        if [[ "$pkg" == "$min_pkg" ]]; then
          marker=" (minimal)"
          break
        fi
      done
      echo "  - ${pkg}${marker}"
    fi
  done
  echo
  echo "Profiles:"
  echo "  --minimal : ${PACKAGES_MINIMAL[*]}"
  echo "  --full    : ${PACKAGES_ALL[*]}"
}

main() {
  local action="install"
  local skip_omz=false
  local selected_packages=()
  local profile=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -l|--list)
        list_packages
        exit 0
        ;;
      -a|--all|--full)
        profile="full"
        shift
        ;;
      --minimal)
        profile="minimal"
        shift
        ;;
      -r|--remove)
        action="remove"
        shift
        ;;
      -n|--no-omz)
        skip_omz=true
        shift
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      --shellcheck)
        shopt -s globstar
        shellcheck -x -- "${SCRIPT_DIR}"/**/*.sh
        exit $?
        ;;
      -*)
        print_error "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        selected_packages+=("$1")
        shift
        ;;
    esac
  done

  # Apply profile if set and no specific packages selected
  if [[ ${#selected_packages[@]} -eq 0 ]]; then
    case "$profile" in
      minimal)
        selected_packages=("${PACKAGES_MINIMAL[@]}")
        ;;
      full|"")
        selected_packages=("${PACKAGES_ALL[@]}")
        ;;
    esac
  fi

  log_verbose "SCRIPT_DIR: ${SCRIPT_DIR}"
  log_verbose "DOTFILES_DIR: ${DOTFILES_DIR}"
  log_verbose "Action: ${action}"
  log_verbose "Skip OMZ: ${skip_omz}"
  log_verbose "Packages: ${selected_packages[*]}"

  check_stow

  if [[ "${action}" == "install" ]]; then
    install_make
  fi

  echo "Dotfiles ${action}ation"
  echo "========================"

  for package in "${selected_packages[@]}"; do
    log_verbose "Processing package: ${package}"
    stow_package "${package}" "${action}"
  done

  # Install oh-my-zsh and fzf if installing zsh package
  if [[ "${action}" == "install" ]] && [[ "${skip_omz}" == false ]]; then
    for pkg in "${selected_packages[@]}"; do
      if [[ "${pkg}" == "zsh" ]]; then
        install_omz
        install_fzf
        break
      fi
    done
  fi

  # Install zsh companion tools (fd, bat, eza, lazygit)
  if [[ "${action}" == "install" ]]; then
    for pkg in "${selected_packages[@]}"; do
      if [[ "${pkg}" == "zsh" ]]; then
        install_fd
        install_bat
        install_eza
        install_lazygit
        install_yq
        break
      fi
    done
  fi

  # Install tmux and TPM if installing tmux package
  if [[ "${action}" == "install" ]]; then
    for pkg in "${selected_packages[@]}"; do
      if [[ "${pkg}" == "tmux" ]]; then
        install_tmux
        install_tpm
        break
      fi
    done
  fi

  # Install ripgrep if installing ripgrep package
  if [[ "${action}" == "install" ]]; then
    for pkg in "${selected_packages[@]}"; do
      if [[ "${pkg}" == "ripgrep" ]]; then
        install_ripgrep
        break
      fi
    done
  fi

  # Install latest Neovim if installing nvim package
  if [[ "${action}" == "install" ]]; then
    for pkg in "${selected_packages[@]}"; do
      if [[ "${pkg}" == "nvim" ]]; then
        install_nvim
        break
      fi
    done
  fi

  # Install Claude Code if installing claude package
  if [[ "${action}" == "install" ]]; then
    for pkg in "${selected_packages[@]}"; do
      if [[ "${pkg}" == "claude" ]]; then
        install_claude_code
        break
      fi
    done
  fi

  # Install Coder CLI if installing coder package
  if [[ "${action}" == "install" ]]; then
    for pkg in "${selected_packages[@]}"; do
      if [[ "${pkg}" == "coder" ]]; then
        install_coder
        break
      fi
    done
  fi

  # Install GitHub CLI if installing gh package
  if [[ "${action}" == "install" ]]; then
    for pkg in "${selected_packages[@]}"; do
      if [[ "${pkg}" == "gh" ]]; then
        install_gh
        break
      fi
    done
  fi

  # Install Go if installing go package
  if [[ "${action}" == "install" ]]; then
    for pkg in "${selected_packages[@]}"; do
      if [[ "${pkg}" == "go" ]]; then
        install_go
        break
      fi
    done
  fi

  echo
  print_success "Done!"
}

main "$@"
