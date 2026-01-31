#!/usr/bin/env bash

# Migration script to update symlinks from old structure to new stow structure.
# This removes old symlinks and re-stows using the new dotfiles/ layout.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

print_success() {
  printf "\e[0;32m  [✔] %s\e[0m\n" "$1"
}

print_info() {
  printf "\e[0;34m  [i] %s\e[0m\n" "$1"
}

# Old symlinks that pointed to home/ directory
OLD_HOME_FILES=(
  ".zshrc"
  ".p10k.zsh"
  ".tmux.conf"
  ".vimrc"
  ".main.gitconfig"
  ".gitignore"
  ".ignore"
  ".ripgreprc"
  ".editorconfig"
)

# Old symlinks that pointed to config/ directory
OLD_CONFIG_DIRS=(
  "nvim"
)

echo "Migration: Old structure → Stow structure"
echo "=========================================="

# Remove old home directory symlinks
print_info "Removing old symlinks from home directory..."
for file in "${OLD_HOME_FILES[@]}"; do
  target="${HOME}/${file}"
  if [[ -L "${target}" ]]; then
    rm "${target}"
    print_success "Removed ${target}"
  fi
done

# Remove old .config symlinks
print_info "Removing old symlinks from ~/.config..."
for dir in "${OLD_CONFIG_DIRS[@]}"; do
  target="${HOME}/.config/${dir}"
  if [[ -L "${target}" ]]; then
    rm "${target}"
    print_success "Removed ${target}"
  fi
done

# Clean up old gitconfig include if present
if grep -q "path=~/.main.gitconfig" "${HOME}/.gitconfig" 2>/dev/null; then
  print_info "Removing old gitconfig include..."
  sed -i '/\[include\]/d; /path=~\/.main.gitconfig/d' "${HOME}/.gitconfig"
  # Remove file if empty
  if [[ ! -s "${HOME}/.gitconfig" ]]; then
    rm "${HOME}/.gitconfig"
  fi
  print_success "Cleaned up ~/.gitconfig"
fi

echo
print_info "Now run ./install.sh to stow the new structure"
