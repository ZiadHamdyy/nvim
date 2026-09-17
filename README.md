# Neovim Config

Personal Neovim setup with Helix-style Space leader maps, lazy.nvim plugins, Rust (rustaceanvim), and Cursor Agent via Avante.

## Requirements

- Neovim **0.10+** (0.11+ recommended)
- `git`, `make` / `cmake` (plugin builds)
- `ripgrep`, `fd` (Telescope)
- Optional: [Cursor Agent CLI](https://cursor.com/docs/cli/installation) for `<leader>i` (Avante)
- Optional formatters/linters: `stylua`, `black`, `prettier`, `ruff`, `eslint_d`, `hadolint`, Rust (`rustfmt` / `clippy`)

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/ZiadHamdyy/nvim/main/setup.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/ZiadHamdyy/nvim.git ~/Public/projects/nvim
cd ~/Public/projects/nvim
./setup.sh
```

The script will:

1. Install system deps (Homebrew on macOS, apt/pacman/dnf on Linux)
2. Install Cursor Agent CLI into `~/.local/bin/agent`
3. Back up any existing `~/.config/nvim`
4. Symlink (or clone) this repo to `~/.config/nvim`
5. Run headless `Lazy! sync`

### Setup options

| Flag | Meaning |
|------|---------|
| `--skip-deps` | Skip package installs |
| `--skip-agent` | Skip Cursor Agent |
| `--copy` | Copy files instead of symlink |
| `--no-sync` | Skip Lazy plugin sync |

```bash
./setup.sh --skip-deps --skip-agent
```

After install, authenticate the agent once if needed:

```bash
agent login
```

## Layout

```
.
├── init.lua          # Full config (options, plugins, keymaps)
├── lazy-lock.json    # Pinned plugin commits
├── setup.sh          # One-shot installer
└── README.md
```

## Keybindings (Space = leader)

| Key | Action |
|-----|--------|
| `Space f` | Find files |
| `Space /` | Search in files |
| `Space e` / `E` | File explorer (cwd / here) |
| `Space b` | Buffers |
| `Space s` / `S` | Document / workspace symbols |
| `Space a` | Code action |
| `Space r` | Rename |
| `Space i` | Cursor AI (Avante) |
| `Space ?` | Command palette |
| `s` | Flash jump |
| `gd` / `gr` / `K` | Definition / references / hover |

## Stack

- **Plugin manager:** [lazy.nvim](https://github.com/folke/lazy.nvim)
- **Theme:** Catppuccin Mocha
- **Completion:** blink.cmp
- **Finder:** Telescope + fzf-native
- **Rust:** rustaceanvim
- **Format:** conform.nvim
- **Lint:** nvim-lint
- **AI:** avante.nvim → `~/.local/bin/agent` (ACP)

## Updating

```bash
cd ~/.config/nvim   # or your clone path
git pull
nvim --headless "+Lazy! sync" "+qa"
```

## Uninstall

```bash
# Restore backup if setup created one
ls ~/.config/nvim.backup.*

rm -rf ~/.config/nvim
# optional: rm -rf ~/.local/share/nvim ~/.local/state/nvim
```
