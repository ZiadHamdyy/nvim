#!/usr/bin/env bash
# =========================================================
# Neovim config installer
# =========================================================
# Installs this config into ~/.config/nvim, system deps,
# Cursor Agent CLI, and syncs lazy.nvim plugins.
#
# Usage:
#   ./setup.sh
#   ./setup.sh --skip-deps
#   ./setup.sh --skip-agent
#   ./setup.sh --copy
#   curl -fsSL https://raw.githubusercontent.com/ZiadHamdyy/nvim/main/setup.sh | bash
# =========================================================

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/ZiadHamdyy/nvim.git}"
REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/ZiadHamdyy/nvim/main}"
NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BACKUP_DIR="${HOME}/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"

SKIP_DEPS=0
SKIP_AGENT=0
USE_COPY=0
NO_SYNC=0

for arg in "$@"; do
  case "$arg" in
    --skip-deps) SKIP_DEPS=1 ;;
    --skip-agent) SKIP_AGENT=1 ;;
    --copy) USE_COPY=1 ;;
    --no-sync) NO_SYNC=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: setup.sh [options]

  --skip-deps    Skip Homebrew / apt dependency install
  --skip-agent   Skip Cursor Agent CLI install
  --copy         Copy config instead of symlink/clone into ~/.config/nvim
  --no-sync      Skip headless Lazy plugin sync
  -h, --help     Show this help
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m!\033[0m %s\n' "$*"; }
fail()  { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Resolve script / source directory (works when run from clone or curl | bash)
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

SOURCE_DIR=""
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/init.lua" ]]; then
  SOURCE_DIR="$SCRIPT_DIR"
fi

ensure_path_local_bin() {
  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"
  case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *) export PATH="$bin_dir:$PATH" ;;
  esac

  local rc=""
  case "$(basename "${SHELL:-zsh}")" in
    bash) rc="$HOME/.bashrc" ;;
    zsh)  rc="$HOME/.zshrc" ;;
    fish)
      mkdir -p "$HOME/.config/fish"
      local fish_rc="$HOME/.config/fish/config.fish"
      if [[ -f "$fish_rc" ]] && ! grep -q '\.local/bin' "$fish_rc" 2>/dev/null; then
        echo 'fish_add_path $HOME/.local/bin' >> "$fish_rc"
        ok "Added ~/.local/bin to PATH in $fish_rc"
      fi
      return
      ;;
    *) rc="$HOME/.zshrc" ;;
  esac

  if [[ -n "$rc" ]]; then
    touch "$rc"
    if ! grep -q '\.local/bin' "$rc" 2>/dev/null; then
      {
        echo ''
        echo '# Neovim / Cursor Agent'
        echo 'export PATH="$HOME/.local/bin:$PATH"'
      } >> "$rc"
      ok "Added ~/.local/bin to PATH in $rc"
    fi
  fi
}

install_macos_deps() {
  if ! have brew; then
    warn "Homebrew not found. Install from https://brew.sh then re-run, or use --skip-deps."
    return
  fi

  info "Installing macOS dependencies with Homebrew..."
  local pkgs=(
    neovim
    git
    ripgrep
    fd
    cmake
    make
    node
    stylua
    black
    prettier
    ruff
    eslint_d
    hadolint
  )

  for pkg in "${pkgs[@]}"; do
    if brew list --formula "$pkg" >/dev/null 2>&1 || brew list --cask "$pkg" >/dev/null 2>&1; then
      ok "$pkg already installed"
    else
      info "brew install $pkg"
      brew install "$pkg" || warn "Failed to install $pkg (continuing)"
    fi
  done

  if ! have rustc || ! have cargo; then
    warn "Rust toolchain not found. Install via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
  else
    ok "Rust toolchain present"
    rustup component add rustfmt clippy rust-analyzer 2>/dev/null || true
  fi
}

install_linux_deps() {
  info "Installing Linux dependencies..."
  if have apt-get; then
    sudo apt-get update -y
    sudo apt-get install -y \
      git curl build-essential cmake \
      ripgrep fd-find \
      neovim \
      nodejs npm \
      python3-pip \
      || warn "Some apt packages failed"
    # fd-find installs as fdfind on Debian/Ubuntu
    if have fdfind && ! have fd; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
  elif have pacman; then
    sudo pacman -Sy --needed --noconfirm \
      git curl base-devel cmake ripgrep fd neovim nodejs npm python-pip \
      || warn "Some pacman packages failed"
  elif have dnf; then
    sudo dnf install -y \
      git curl gcc gcc-c++ make cmake ripgrep fd-find neovim nodejs npm python3-pip \
      || warn "Some dnf packages failed"
  else
    warn "Unsupported package manager. Install neovim, git, ripgrep, fd, cmake, node manually."
  fi

  # Formatters / linters (best-effort)
  if have npm; then
    npm install -g prettier eslint_d 2>/dev/null || warn "npm global install failed"
  fi
  if have pip3 || have pip; then
    local pip_cmd
    pip_cmd="$(command -v pip3 || command -v pip)"
    "$pip_cmd" install --user black ruff 2>/dev/null || warn "pip install failed"
  fi
  if have cargo; then
    cargo install stylua 2>/dev/null || true
  fi
  if ! have rustc || ! have cargo; then
    warn "Rust toolchain not found. Install via rustup for rustaceanvim / rustfmt."
  else
    rustup component add rustfmt clippy rust-analyzer 2>/dev/null || true
  fi
}

install_deps() {
  if [[ "$SKIP_DEPS" -eq 1 ]]; then
    info "Skipping system dependencies (--skip-deps)"
    return
  fi

  case "$(uname -s)" in
    Darwin) install_macos_deps ;;
    Linux)  install_linux_deps ;;
    *)      warn "Unsupported OS: $(uname -s). Install Neovim >= 0.10 and build tools manually." ;;
  esac

  have nvim || fail "Neovim (nvim) is required but not found on PATH"
  have git  || fail "git is required but not found on PATH"
  ok "Core tools ready (nvim $(nvim --version | head -1))"
}

install_cursor_agent() {
  if [[ "$SKIP_AGENT" -eq 1 ]]; then
    info "Skipping Cursor Agent (--skip-agent)"
    return
  fi

  ensure_path_local_bin

  if have agent || [[ -x "$HOME/.local/bin/agent" ]]; then
    ok "Cursor Agent already installed"
  else
    info "Installing Cursor Agent CLI..."
    curl -fsSL https://cursor.com/install | bash || warn "Cursor Agent install failed"
    ensure_path_local_bin
  fi

  if have agent || [[ -x "$HOME/.local/bin/agent" ]]; then
    ok "Cursor Agent: $(agent --version 2>/dev/null || "$HOME/.local/bin/agent" --version 2>/dev/null || echo present)"
    info "Run 'agent login' once if Avante AI is not authenticated yet."
  else
    warn "Cursor Agent not found after install. Avante (<leader>i) needs ~/.local/bin/agent"
  fi
}

backup_existing_config() {
  if [[ ! -e "$NVIM_CONFIG" ]]; then
    return
  fi

  # Already this repo (same path) — nothing to do
  if [[ -n "$SOURCE_DIR" && "$(cd "$NVIM_CONFIG" 2>/dev/null && pwd)" == "$SOURCE_DIR" ]]; then
    ok "Config already at $NVIM_CONFIG"
    return
  fi

  info "Backing up existing config to $BACKUP_DIR"
  mv "$NVIM_CONFIG" "$BACKUP_DIR"
  ok "Backup saved"
}

install_config() {
  mkdir -p "$(dirname "$NVIM_CONFIG")"

  # Already running from ~/.config/nvim
  if [[ -n "$SOURCE_DIR" && "$(cd "$SOURCE_DIR" && pwd)" == "$(cd "$NVIM_CONFIG" 2>/dev/null && pwd || true)" ]]; then
    ok "Using existing checkout at $NVIM_CONFIG"
    return
  fi

  backup_existing_config

  if [[ -n "$SOURCE_DIR" ]]; then
    if [[ "$USE_COPY" -eq 1 ]]; then
      info "Copying config from $SOURCE_DIR -> $NVIM_CONFIG"
      mkdir -p "$NVIM_CONFIG"
      rsync -a --exclude .git "$SOURCE_DIR/" "$NVIM_CONFIG/" 2>/dev/null \
        || { cp -R "$SOURCE_DIR"/. "$NVIM_CONFIG/"; }
    else
      info "Symlinking $SOURCE_DIR -> $NVIM_CONFIG"
      ln -sfn "$SOURCE_DIR" "$NVIM_CONFIG"
    fi
  else
    info "Cloning $REPO_URL -> $NVIM_CONFIG"
    git clone --depth 1 "$REPO_URL" "$NVIM_CONFIG"
  fi

  [[ -f "$NVIM_CONFIG/init.lua" ]] || fail "init.lua missing after install"
  ok "Config installed at $NVIM_CONFIG"
}

sync_plugins() {
  if [[ "$NO_SYNC" -eq 1 ]]; then
    info "Skipping Lazy sync (--no-sync)"
    return
  fi

  have nvim || fail "nvim not found"

  info "Syncing lazy.nvim plugins (headless)..."
  # Lazy! sync installs + builds plugins (avante, telescope-fzf-native, etc.)
  nvim --headless "+Lazy! sync" "+qa" || {
    warn "Headless Lazy sync reported errors. Open nvim and run :Lazy sync"
    return
  }
  ok "Plugins synced"
}

print_next_steps() {
  cat <<EOF

=========================================================
  Neovim config installed
=========================================================

  Config:  $NVIM_CONFIG
  Open:    nvim

  Useful keys:
    <Space>f   Find files
    <Space>/   Live grep
    <Space>e   File explorer
    <Space>i   Cursor AI (Avante)
    <Space>?   Command palette

  If Avante needs auth:
    agent login

  Re-sync plugins later:
    nvim --headless "+Lazy! sync" "+qa"

EOF
}

main() {
  info "Starting Neovim setup"
  ensure_path_local_bin
  install_deps
  install_cursor_agent
  install_config
  sync_plugins
  print_next_steps
}

main
