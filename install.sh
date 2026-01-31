#!/usr/bin/env bash

# Dotfiles installation script using GNU Stow.
# Usage: ./install.sh [options] [packages...]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"
PACKAGES=(zsh tmux vim git nvim ripgrep editorconfig)

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
  --shellcheck    Lint all shell scripts

PACKAGES:
  ${PACKAGES[*]}

If no packages specified, all packages will be installed.

EXAMPLES:
  $0                    # Install all packages
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

install_stow() {
  print_info "Installing GNU Stow..."

  if command -v apt &>/dev/null; then
    sudo apt update && sudo apt install -y stow
  elif command -v brew &>/dev/null; then
    brew install stow
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm stow
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y stow
  else
    print_error "Could not detect package manager. Install stow manually."
    exit 1
  fi

  if command -v stow &>/dev/null; then
    print_success "Installed stow"
  else
    print_error "Failed to install stow"
    exit 1
  fi
}

check_stow() {
  if ! command -v stow &>/dev/null; then
    install_stow
  fi
}

install_omz() {
  print_info "Setting up oh-my-zsh..."

  ZSH="${HOME}/.oh-my-zsh"
  ZSH_CUSTOM="${ZSH_CUSTOM:-${ZSH}/custom}"

  # Clone or update Oh My Zsh.
  if [[ ! -d "${ZSH}" ]]; then
    git clone --quiet --filter=blob:none https://github.com/robbyrussell/oh-my-zsh "${ZSH}"
    print_success "Installed oh-my-zsh"
  else
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
  if [[ ! -d "${THEME_PATH}" ]]; then
    git clone --quiet --filter=blob:none --branch "${THEME_VERSION_TAG}" "${THEME_REPO_URL}" "${THEME_PATH}"
    print_success "Installed powerlevel10k"
  else
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
    if [[ ! -d "${PLUGIN_PATH}" ]]; then
      git clone --quiet --filter=blob:none "${REPO_URL}" "${PLUGIN_PATH}"
      print_success "Installed plugin: ${PLUGIN_NAME}"
    else
      git -C "${PLUGIN_PATH}" pull --quiet
      print_success "Updated plugin: ${PLUGIN_NAME}"
    fi
  done
}

install_fzf() {
  print_info "Setting up fzf..."

  FZF_DIR="${HOME}/.fzf"

  if [[ ! -d "${FZF_DIR}" ]]; then
    git clone --quiet --depth 1 https://github.com/junegunn/fzf.git "${FZF_DIR}"
    print_success "Cloned fzf"
  else
    git -C "${FZF_DIR}" pull --quiet
    print_success "Updated fzf"
  fi

  # Install fzf binary and shell integrations (non-interactively)
  "${FZF_DIR}/install" --bin --no-bash --no-zsh --no-fish >/dev/null 2>&1
  print_success "Installed fzf binary"
}

stow_package() {
  local package=$1
  local action=$2

  if [[ ! -d "${DOTFILES_DIR}/${package}" ]]; then
    print_error "Package '${package}' not found"
    return 1
  fi

  # Ensure ~/.config exists for packages that need it
  if [[ -d "${DOTFILES_DIR}/${package}/.config" ]]; then
    mkdir -p "${HOME}/.config"
  fi

  if [[ "${action}" == "remove" ]]; then
    stow -d "${DOTFILES_DIR}" -t "${HOME}" -D "${package}" 2>/dev/null && \
      print_success "Removed ${package}" || \
      print_info "Package ${package} was not stowed"
  else
    # Use --adopt to handle existing files, then restore from git
    if stow -d "${DOTFILES_DIR}" -t "${HOME}" --adopt "${package}" 2>/dev/null; then
      # Restore any adopted files to our version
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
  for pkg in "${PACKAGES[@]}"; do
    if [[ -d "${DOTFILES_DIR}/${pkg}" ]]; then
      echo "  - ${pkg}"
    fi
  done
}

main() {
  local action="install"
  local skip_omz=false
  local selected_packages=()

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
      -a|--all)
        selected_packages=("${PACKAGES[@]}")
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

  # Default to all packages if none specified
  if [[ ${#selected_packages[@]} -eq 0 ]]; then
    selected_packages=("${PACKAGES[@]}")
  fi

  check_stow

  echo "Dotfiles ${action}ation"
  echo "========================"

  for package in "${selected_packages[@]}"; do
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

  echo
  print_success "Done!"
}

main "$@"
