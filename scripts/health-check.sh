#!/usr/bin/env bash

# Health check script for dotfiles installation.
# Verifies symlinks, tools, and plugins are correctly installed.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR}/../dotfiles"

# Counters
PASS=0
FAIL=0
WARN=0

print_header() {
  echo
  printf "\e[1;34m=== %s ===\e[0m\n" "$1"
}

print_pass() {
  printf "\e[0;32m  [✔] %s\e[0m\n" "$1"
  ((PASS++))
}

print_fail() {
  printf "\e[0;31m  [✖] %s\e[0m\n" "$1"
  ((FAIL++))
}

print_warn() {
  printf "\e[0;33m  [!] %s\e[0m\n" "$1"
  ((WARN++))
}

print_info() {
  printf "\e[0;34m  [i] %s\e[0m\n" "$1"
}

# Check if a command exists
check_command() {
  local cmd=$1
  local name=${2:-$1}
  if command -v "$cmd" &>/dev/null; then
    print_pass "$name is installed"
    return 0
  else
    print_fail "$name is not installed"
    return 1
  fi
}

# Check if a command exists (optional - warn instead of fail)
check_command_optional() {
  local cmd=$1
  local name=${2:-$1}
  if command -v "$cmd" &>/dev/null; then
    print_pass "$name is installed"
    return 0
  else
    print_warn "$name is not installed (optional)"
    return 1
  fi
}

# Check if a symlink points to our dotfiles
check_symlink() {
  local target=$1
  local expected_source=$2
  local name=${3:-$target}

  if [[ -L "$target" ]]; then
    local actual_source
    actual_source=$(readlink -f "$target")
    local expected_resolved
    expected_resolved=$(readlink -f "$expected_source")
    if [[ "$actual_source" == "$expected_resolved" ]]; then
      print_pass "$name symlink is correct"
      return 0
    else
      print_fail "$name symlink points to wrong location"
      print_info "  Expected: $expected_resolved"
      print_info "  Actual:   $actual_source"
      return 1
    fi
  elif [[ -e "$target" ]]; then
    print_warn "$name exists but is not a symlink"
    return 1
  else
    print_fail "$name does not exist"
    return 1
  fi
}

# Check if a directory exists
check_directory() {
  local dir=$1
  local name=${2:-$dir}
  if [[ -d "$dir" ]]; then
    print_pass "$name exists"
    return 0
  else
    print_fail "$name does not exist"
    return 1
  fi
}

# Check if a file exists
check_file() {
  local file=$1
  local name=${2:-$file}
  if [[ -f "$file" ]]; then
    print_pass "$name exists"
    return 0
  else
    print_fail "$name does not exist"
    return 1
  fi
}

##############################################################################
# Core Tools
##############################################################################
check_core_tools() {
  print_header "Core Tools"
  check_command stow "GNU Stow"
  check_command git "Git"
  check_command zsh "Zsh"
  check_command tmux "Tmux"
  check_command vim "Vim"
}

##############################################################################
# Enhanced Tools
##############################################################################
check_enhanced_tools() {
  print_header "Enhanced Tools"
  check_command_optional nvim "Neovim"
  check_command_optional fzf "fzf"
  check_command_optional fd "fd"
  check_command_optional rg "ripgrep"
  check_command_optional bat "bat" || check_command_optional batcat "bat (batcat)"
  check_command_optional eza "eza"
  check_command_optional delta "delta (git pager)"
}

##############################################################################
# Symlinks
##############################################################################
check_symlinks() {
  print_header "Symlinks"

  # Zsh
  check_symlink "${HOME}/.zshrc" "${DOTFILES_DIR}/zsh/.zshrc" ".zshrc"
  check_symlink "${HOME}/.p10k.zsh" "${DOTFILES_DIR}/zsh/.p10k.zsh" ".p10k.zsh"

  # Tmux
  check_symlink "${HOME}/.tmux.conf" "${DOTFILES_DIR}/tmux/.tmux.conf" ".tmux.conf"

  # Vim
  check_symlink "${HOME}/.vimrc" "${DOTFILES_DIR}/vim/.vimrc" ".vimrc"

  # Git
  check_symlink "${HOME}/.gitconfig" "${DOTFILES_DIR}/git/.gitconfig" ".gitconfig"
  check_symlink "${HOME}/.gitignore" "${DOTFILES_DIR}/git/.gitignore" ".gitignore (global)"

  # Neovim
  check_symlink "${HOME}/.config/nvim" "${DOTFILES_DIR}/nvim/.config/nvim" ".config/nvim"

  # Ripgrep
  check_symlink "${HOME}/.ripgreprc" "${DOTFILES_DIR}/ripgrep/.ripgreprc" ".ripgreprc"

  # Editorconfig
  check_symlink "${HOME}/.editorconfig" "${DOTFILES_DIR}/editorconfig/.editorconfig" ".editorconfig"
}

##############################################################################
# Oh-My-Zsh
##############################################################################
check_omz() {
  print_header "Oh-My-Zsh"

  check_directory "${HOME}/.oh-my-zsh" "Oh-My-Zsh"
  check_directory "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" "Powerlevel10k theme"
  check_directory "${HOME}/.oh-my-zsh/custom/plugins/fzf-tab" "fzf-tab plugin"
  check_directory "${HOME}/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" "fast-syntax-highlighting plugin"
  check_directory "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "zsh-autosuggestions plugin"
}

##############################################################################
# FZF
##############################################################################
check_fzf() {
  print_header "FZF Installation"

  if check_directory "${HOME}/.fzf" "fzf directory"; then
    check_file "${HOME}/.fzf/bin/fzf" "fzf binary"
    check_file "${HOME}/.fzf/shell/key-bindings.zsh" "fzf key-bindings"
    check_file "${HOME}/.fzf/shell/completion.zsh" "fzf completion"
  fi
}

##############################################################################
# Tmux Plugins
##############################################################################
check_tmux_plugins() {
  print_header "Tmux Plugins (TPM)"

  if check_directory "${HOME}/.tmux/plugins/tpm" "TPM (Tmux Plugin Manager)"; then
    check_directory "${HOME}/.tmux/plugins/tmux-resurrect" "tmux-resurrect" || \
      print_info "Run 'prefix + I' in tmux to install plugins"
    check_directory "${HOME}/.tmux/plugins/tmux-continuum" "tmux-continuum" || \
      print_info "Run 'prefix + I' in tmux to install plugins"
  else
    print_info "Install TPM: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
  fi
}

##############################################################################
# Neovim Plugins
##############################################################################
check_nvim_plugins() {
  print_header "Neovim Plugins"

  if command -v nvim &>/dev/null; then
    check_directory "${HOME}/.local/share/nvim/lazy" "lazy.nvim plugin directory" || \
      print_info "Run 'nvim' to bootstrap lazy.nvim"
  else
    print_info "Neovim not installed, skipping plugin check"
  fi
}

##############################################################################
# Vim Plugins
##############################################################################
check_vim_plugins() {
  print_header "Vim Plugins"

  check_file "${HOME}/.vim/autoload/plug.vim" "vim-plug" || \
    print_info "vim-plug not installed. Run: curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
}

##############################################################################
# Shell Configuration
##############################################################################
check_shell_config() {
  print_header "Shell Configuration"

  local current_shell
  current_shell=$(basename "$SHELL")

  if [[ "$current_shell" == "zsh" ]]; then
    print_pass "Default shell is zsh"
  else
    print_warn "Default shell is $current_shell (expected zsh)"
    print_info "Change shell: chsh -s \$(which zsh)"
  fi
}

##############################################################################
# Summary
##############################################################################
print_summary() {
  echo
  printf "\e[1;34m=== Summary ===\e[0m\n"
  printf "\e[0;32m  Passed: %d\e[0m\n" "$PASS"
  printf "\e[0;33m  Warnings: %d\e[0m\n" "$WARN"
  printf "\e[0;31m  Failed: %d\e[0m\n" "$FAIL"
  echo

  if [[ $FAIL -eq 0 ]]; then
    printf "\e[0;32mAll critical checks passed!\e[0m\n"
    return 0
  else
    printf "\e[0;31mSome checks failed. Run './install.sh' to fix issues.\e[0m\n"
    return 1
  fi
}

##############################################################################
# Main
##############################################################################
main() {
  echo "Dotfiles Health Check"
  echo "====================="

  check_core_tools
  check_enhanced_tools
  check_symlinks
  check_omz
  check_fzf
  check_tmux_plugins
  check_nvim_plugins
  check_vim_plugins
  check_shell_config

  print_summary
}

main "$@"
