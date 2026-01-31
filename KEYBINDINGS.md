# Keybindings Cheat Sheet

Quick reference for all keybindings in this dotfiles configuration.

## Tmux

**Prefix:** `Ctrl+Space`

### Session Management
| Key | Action |
|-----|--------|
| `prefix d` | Detach from session |
| `prefix s` | List sessions |
| `prefix $` | Rename session |

### Window Management
| Key | Action |
|-----|--------|
| `prefix c` | New window (in current path) |
| `prefix ,` | Rename window |
| `prefix n` | Next window |
| `prefix p` | Previous window |
| `prefix 0-9` | Switch to window number |
| `prefix Space` | Last window |
| `prefix &` | Kill window |

### Pane Management
| Key | Action |
|-----|--------|
| `prefix \|` | Split horizontal |
| `prefix -` | Split vertical |
| `prefix \\` | Split horizontal (full width) |
| `prefix _` | Split vertical (full height) |
| `prefix h/j/k/l` | Navigate panes (vim-style) |
| `Alt+h/j/k/l` | Resize pane |
| `prefix x` | Kill pane |
| `prefix z` | Toggle pane zoom |
| `prefix {` | Swap pane left |
| `prefix }` | Swap pane right |

### Copy Mode (vi-style)
| Key | Action |
|-----|--------|
| `prefix [` | Enter copy mode |
| `v` | Begin selection |
| `y` | Copy selection |
| `q` | Exit copy mode |

### Plugins
| Key | Action |
|-----|--------|
| `prefix I` | Install plugins (TPM) |
| `prefix U` | Update plugins (TPM) |
| `prefix Ctrl+s` | Save session (resurrect) |
| `prefix Ctrl+r` | Restore session (resurrect) |

### Other
| Key | Action |
|-----|--------|
| `prefix r` | Reload config |

---

## Zsh / Shell

### Vi Mode
| Key | Action |
|-----|--------|
| `Esc` | Enter normal mode |
| `i` | Enter insert mode |
| `v` | Edit command in $EDITOR |

### History
| Key | Action |
|-----|--------|
| `Ctrl+r` | Search history backward |
| `↑/↓` | Navigate history |

### FZF Integration
| Key | Action |
|-----|--------|
| `Ctrl+t` | Fuzzy file finder |
| `Ctrl+r` | Fuzzy history search |
| `Alt+c` | Fuzzy directory change |

### FZF Preview Navigation
| Key | Action |
|-----|--------|
| `Alt+j` | Preview scroll down |
| `Alt+k` | Preview scroll up |
| `Alt+d` | Preview page down |
| `Alt+u` | Preview page up |

### General
| Key | Action |
|-----|--------|
| `Home` | Beginning of line |
| `End` | End of line |
| `Delete` | Delete character |

---

## Git Aliases

### Basic Commands
| Alias | Command | Description |
|-------|---------|-------------|
| `co` | `checkout` | Switch branches |
| `br` | `branch` | List/create branches |
| `ci` | `commit` | Commit changes |
| `st` | `status` | Show status |
| `cp` | `cherry-pick` | Cherry-pick commit |
| `up` | `push -u origin HEAD` | Push current branch |

### Diff & Staging
| Alias | Command | Description |
|-------|---------|-------------|
| `diff` | `diff --word-diff` | Word-level diff |
| `dc` | `diff --cached` | Diff staged changes |

### Stash
| Alias | Command | Description |
|-------|---------|-------------|
| `sl` | `stash list` | List stashes |
| `sa` | `stash apply` | Apply stash |
| `ss` | `stash push` | Save stash |
| `sp` | `stash pop` | Pop stash |

### Rebase
| Alias | Command | Description |
|-------|---------|-------------|
| `ri` | `rebase --interactive` | Interactive rebase |
| `ra` | `rebase --abort` | Abort rebase |
| `rc` | `rebase --continue` | Continue rebase |

### Log Views
| Alias | Description |
|-------|-------------|
| `ls` | Compact log with colors |
| `ll` | Log with file stats |
| `ld` | Log with relative dates |
| `lds` | Log with short dates |
| `le` | Oneline decorated log |
| `logtree` | Graph view of all branches |

### File Operations
| Alias | Command | Description |
|-------|---------|-------------|
| `f` | `ls-files \| grep -i` | Find tracked files |
| `fl` | `log -u` | File history |
| `gr` | `grep -Iin` | Search in files |

### Workflow
| Alias | Description |
|-------|-------------|
| `or` | Fetch & checkout origin/main |
| `prep` | Fetch & rebase on origin/main |
| `mm` | Fetch & merge origin/main |
| `amend` | Amend last commit |
| `sc` | Show commit details |

### Assume Unchanged
| Alias | Description |
|-------|-------------|
| `assume` | Mark file as unchanged |
| `unassume` | Unmark file |
| `assumed` | List assumed files |
| `assumeall` | Assume all modified files |
| `unassumeall` | Unassume all files |

---

## Neovim

### General (LazyVim defaults)
| Key | Action |
|-----|--------|
| `Space` | Leader key |
| `<leader>e` | File explorer |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Find buffers |
| `<leader>:` | Command history |

### Flash.nvim (Jump/Search)
| Key | Action |
|-----|--------|
| `s` | Flash jump |
| `S` | Flash treesitter |
| `r` | Remote flash (operator) |

### LSP (C/C++)
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Go to references |
| `gI` | Go to implementation |
| `K` | Hover documentation |
| `<leader>ca` | Code actions |
| `<leader>cr` | Rename symbol |
| `<leader>cf` | Format file |
| `<leader>cc` | Regenerate compile commands (clangd) |

### Debugging (DAP)
| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | Toggle REPL |

### Cursor Agent
| Key | Action |
|-----|--------|
| `<leader>zz` | Toggle Cursor Agent terminal |
| `<leader>zz` (visual) | Send selection to agent |
| `<leader>zZ` | Send buffer to agent |

### Commands
| Command | Description |
|---------|-------------|
| `:LspUpdate` | Regenerate compile commands |

---

## Vim

### Plugin Keybindings
| Key | Action |
|-----|--------|
| `Ctrl+p` | FZF file finder |
| `<leader>b` | FZF buffers |

---

## Shell Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `vim` | `nvim` | Use Neovim |
| `vi` | `nvim` | Use Neovim |
| `ls` | `eza` | Modern ls |
| `ll` | `eza -l` | Long listing |
| `cat` | `bat` | Syntax-highlighted cat |
| `find` | `fd` | Modern find |
| `grep` | `rg` | Ripgrep |
