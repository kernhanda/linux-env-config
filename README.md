# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

```
dotfiles/
├── zsh/           # Zsh shell configuration
│   ├── .zshrc
│   └── .p10k.zsh
├── tmux/          # Tmux terminal multiplexer
│   └── .tmux.conf
├── vim/           # Vim configuration
│   └── .vimrc
├── git/           # Git configuration
│   ├── .gitconfig
│   ├── .gitignore_global
│   └── .ignore
├── nvim/          # Neovim (LazyVim)
│   └── .config/nvim/
├── ripgrep/       # Ripgrep configuration
│   └── .ripgreprc
└── editorconfig/  # EditorConfig
    └── .editorconfig
```

## Installation

### Prerequisites

Install GNU Stow:

```bash
# Ubuntu/Debian
sudo apt install stow

# macOS
brew install stow

# Arch
sudo pacman -S stow
```

### Quick Start

```bash
git clone https://github.com/kernhanda/linux-env-config.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

### Selective Installation

Install specific packages only:

```bash
./install.sh zsh nvim      # Install only zsh and nvim
./install.sh -l            # List available packages
./install.sh -n            # Install all, skip oh-my-zsh setup
```

### Manual Stow Usage

You can also use stow directly:

```bash
cd ~/.dotfiles
stow -d dotfiles -t ~ zsh      # Install zsh config
stow -d dotfiles -t ~ -D zsh   # Remove zsh config
```

## Uninstallation

```bash
./install.sh -r            # Remove all packages
./install.sh -r zsh nvim   # Remove specific packages
```

## Packages

| Package | Description | Files |
|---------|-------------|-------|
| `zsh` | Zsh with Oh-My-Zsh, Powerlevel10k, and plugins | `.zshrc`, `.p10k.zsh` |
| `tmux` | Tmux with vim-style navigation | `.tmux.conf` |
| `vim` | Minimal Vim configuration | `.vimrc` |
| `git` | Git aliases and delta pager | `.gitconfig`, `.gitignore_global` |
| `nvim` | Neovim with LazyVim | `.config/nvim/` |
| `ripgrep` | Ripgrep with custom file types | `.ripgreprc` |
| `editorconfig` | EditorConfig settings | `.editorconfig` |

## Docker

A pre-configured environment is available as a Docker image:

```bash
docker pull kernhanda/linux-env-config
docker run -it kernhanda/linux-env-config
```

## Credits

Inspired by [mrpickles/dotfiles](https://github.com/mrpickles/dotfiles).
