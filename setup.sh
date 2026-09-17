#!/usr/bin/env bash
# =========================================================
# Neovim config installer
# =========================================================
# Installs this config into ~/.config/nvim, system deps,
# Cursor Agent CLI, Rust toolchain, and syncs lazy.nvim.
#
# Usage:
#   ./setup.sh
#   ./setup.sh --skip-deps --skip-agent
#   ./setup.sh --copy --force
#   curl -fsSL https://raw.githubusercontent.com/ZiadHamdyy/nvim/main/setup.sh | bash
# =========================================================

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/ZiadHamdyy/nvim.git}"
NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BACKUP_DIR="${HOME}/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
LAZY_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy"

SKIP_DEPS=0
SKIP_AGENT=0
SKIP_RUST=0
USE_COPY=0
NO_SYNC=0
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --skip-deps) SKIP_DEPS=1 ;;
    --skip-agent) SKIP_AGENT=1 ;;
    --skip-rust) SKIP_RUST=1 ;;
    --copy) USE_COPY=1 ;;
    --no-sync) NO_SYNC=1 ;;
    --force) FORCE=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: setup.sh [options]

  --skip-deps    Skip Homebrew / apt dependency install
  --skip-agent   Skip Cursor Agent CLI install
  --skip-rust    Skip rustup / Rust toolchain install
  --copy         Copy config instead of symlink into ~/.config/nvim
  --no-sync      Skip headless Lazy plugin sync
  --force        Replace existing ~/.config/nvim even if it looks current
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

realpath_safe() {
  if have realpath; then
    realpath "$1" 2>/dev/null || true
  elif have python3; then
    python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1" 2>/dev/null || true
  else
    (cd "$1" 2>/dev/null && pwd) || true
  fi
}

same_path() {
  local a b
  a="$(realpath_safe "$1")"
  b="$(realpath_safe "$2")"
  [[ -n "$a" && -n "$b" && "$a" == "$b" ]]
}

ensure_path_local_bin() {
  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"
  case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *) export PATH="$bin_dir:$PATH" ;;
  esac

  # cargo / rustup bins
  if [[ -d "$HOME/.cargo/bin" ]]; then
    case ":$PATH:" in
      *":$HOME/.cargo/bin:"*) ;;
      *) export PATH="$HOME/.cargo/bin:$PATH" ;;
    esac
  fi

  local rc=""
  case "$(basename "${SHELL:-zsh}")" in
    bash) rc="$HOME/.bashrc" ;;
    zsh)  rc="$HOME/.zshrc" ;;
    fish)
      mkdir -p "$HOME/.config/fish"
      local fish_rc="$HOME/.config/fish/config.fish"
      touch "$fish_rc"
      if ! grep -q '\.local/bin' "$fish_rc" 2>/dev/null; then
        echo 'fish_add_path $HOME/.local/bin' >> "$fish_rc"
        ok "Added ~/.local/bin to PATH in $fish_rc"
      fi
      if [[ -d "$HOME/.cargo/bin" ]] && ! grep -q '\.cargo/bin' "$fish_rc" 2>/dev/null; then
        echo 'fish_add_path $HOME/.cargo/bin' >> "$fish_rc"
        ok "Added ~/.cargo/bin to PATH in $fish_rc"
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
    if [[ -d "$HOME/.cargo/bin" ]] && ! grep -q '\.cargo/bin' "$rc" 2>/dev/null; then
      {
        echo ''
        echo '# Rust / cargo'
        echo 'export PATH="$HOME/.cargo/bin:$PATH"'
      } >> "$rc"
      ok "Added ~/.cargo/bin to PATH in $rc"
    fi
  fi
}

ensure_macos_build_tools() {
  if ! xcode-select -p >/dev/null 2>&1; then
    warn "Xcode Command Line Tools missing. Triggering install (GUI prompt)..."
    xcode-select --install 2>/dev/null || true
    warn "Finish the CLT install, then re-run ./setup.sh"
  else
    ok "Xcode Command Line Tools present"
  fi
}

install_rust() {
  if [[ "$SKIP_RUST" -eq 1 ]]; then
    info "Skipping Rust toolchain (--skip-rust)"
    return
  fi

  if have rustc && have cargo && have rustup; then
    ok "Rust toolchain present ($(rustc --version 2>/dev/null | awk '{print $2}'))"
  else
    info "Installing Rust via rustup (non-interactive)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || {
      warn "rustup install failed"
      return
    }
    # shellcheck disable=SC1091
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    ensure_path_local_bin
  fi

  if have rustup; then
    rustup default stable >/dev/null 2>&1 || true
    rustup component add rustfmt clippy rust-analyzer 2>/dev/null || true
    ok "Rust components: rustfmt, clippy, rust-analyzer"
  fi
}

brew_install() {
  local pkg="$1"
  if brew list --formula "$pkg" >/dev/null 2>&1 || brew list --cask "$pkg" >/dev/null 2>&1; then
    ok "$pkg already installed"
  else
    info "brew install $pkg"
    brew install "$pkg" || warn "Failed to install $pkg (continuing)"
  fi
}

install_macos_deps() {
  if ! have brew; then
    warn "Homebrew not found. Install from https://brew.sh then re-run, or use --skip-deps."
    return
  fi

  ensure_macos_build_tools

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
    brew_install "$pkg"
  done

  # Icons in nvim-web-devicons / which-key look best with a Nerd Font
  if ! brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    info "Installing JetBrainsMono Nerd Font (optional, for icons)..."
    brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null \
      || warn "Nerd Font install skipped (tap font-jetbrains-mono-nerd-font manually if needed)"
  else
    ok "JetBrainsMono Nerd Font already installed"
  fi
}

install_linux_deps() {
  info "Installing Linux dependencies..."
  if have apt-get; then
    sudo apt-get update -y
    sudo apt-get install -y \
      git curl build-essential cmake pkg-config \
      ripgrep fd-find \
      neovim \
      nodejs npm \
      python3-pip \
      unzip \
      || warn "Some apt packages failed"
    if have fdfind && ! have fd; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
      ok "Linked fdfind -> ~/.local/bin/fd"
    fi
  elif have pacman; then
    sudo pacman -Sy --needed --noconfirm \
      git curl base-devel cmake pkgconf ripgrep fd neovim nodejs npm python-pip unzip \
      || warn "Some pacman packages failed"
  elif have dnf; then
    sudo dnf install -y \
      git curl gcc gcc-c++ make cmake pkgconf-pkg-config \
      ripgrep fd-find neovim nodejs npm python3-pip unzip \
      || warn "Some dnf packages failed"
  else
    warn "Unsupported package manager. Install neovim, git, ripgrep, fd, cmake, node manually."
  fi

  if have npm; then
    npm install -g prettier eslint_d 2>/dev/null || warn "npm global install failed"
  fi
  if have pip3 || have pip; then
    local pip_cmd
    pip_cmd="$(command -v pip3 || command -v pip)"
    "$pip_cmd" install --user black ruff 2>/dev/null || warn "pip install failed"
  fi
  if have cargo; then
    cargo install stylua --locked 2>/dev/null || cargo install stylua 2>/dev/null || true
  elif have curl; then
    # stylua release binary fallback when cargo missing (after rust install may exist)
    :
  fi
}

install_deps() {
  if [[ "$SKIP_DEPS" -eq 1 ]]; then
    info "Skipping system dependencies (--skip-deps)"
  else
    case "$(uname -s)" in
      Darwin) install_macos_deps ;;
      Linux)  install_linux_deps ;;
      *)      warn "Unsupported OS: $(uname -s). Install Neovim >= 0.10 and build tools manually." ;;
    esac
  fi

  install_rust

  have nvim || fail "Neovim (nvim) is required but not found on PATH"
  have git  || fail "git is required but not found on PATH"
  have make || warn "make not found — avante.nvim / telescope-fzf-native builds may fail"
  have cmake || warn "cmake not found — some native builds may fail"
  ok "Core tools ready ($(nvim --version | head -1))"
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

  local agent_bin=""
  if have agent; then
    agent_bin="$(command -v agent)"
  elif [[ -x "$HOME/.local/bin/agent" ]]; then
    agent_bin="$HOME/.local/bin/agent"
  fi

  if [[ -n "$agent_bin" ]]; then
    ok "Cursor Agent: $("$agent_bin" --version 2>/dev/null || echo present) ($agent_bin)"
    info "Run 'agent login' once if Avante AI is not authenticated yet."
  else
    warn "Cursor Agent not found after install. Avante (<leader>i) needs ~/.local/bin/agent"
  fi
}

backup_existing_config() {
  if [[ ! -e "$NVIM_CONFIG" && ! -L "$NVIM_CONFIG" ]]; then
    return
  fi

  if [[ "$FORCE" -eq 0 ]] && [[ -n "$SOURCE_DIR" ]] && same_path "$NVIM_CONFIG" "$SOURCE_DIR"; then
    ok "Config already at $NVIM_CONFIG"
    return 1
  fi

  info "Backing up existing config to $BACKUP_DIR"
  mv "$NVIM_CONFIG" "$BACKUP_DIR"
  ok "Backup saved → $BACKUP_DIR"
}

install_config() {
  mkdir -p "$(dirname "$NVIM_CONFIG")"

  if [[ "$FORCE" -eq 0 ]] && [[ -n "$SOURCE_DIR" ]] && same_path "$SOURCE_DIR" "$NVIM_CONFIG"; then
    ok "Using existing checkout at $NVIM_CONFIG"
    return
  fi

  if [[ -e "$NVIM_CONFIG" || -L "$NVIM_CONFIG" ]]; then
    if ! backup_existing_config; then
      return
    fi
  fi

  if [[ -n "$SOURCE_DIR" ]]; then
    if [[ "$USE_COPY" -eq 1 ]]; then
      info "Copying config from $SOURCE_DIR → $NVIM_CONFIG"
      mkdir -p "$NVIM_CONFIG"
      if have rsync; then
        rsync -a --exclude .git "$SOURCE_DIR/" "$NVIM_CONFIG/"
      else
        cp -R "$SOURCE_DIR"/. "$NVIM_CONFIG/"
        rm -rf "$NVIM_CONFIG/.git" 2>/dev/null || true
      fi
    else
      info "Symlinking $SOURCE_DIR → $NVIM_CONFIG"
      ln -sfn "$SOURCE_DIR" "$NVIM_CONFIG"
    fi
  else
    info "Cloning $REPO_URL → $NVIM_CONFIG"
    git clone --depth 1 "$REPO_URL" "$NVIM_CONFIG"
  fi

  [[ -f "$NVIM_CONFIG/init.lua" ]] || fail "init.lua missing after install"
  [[ -f "$NVIM_CONFIG/lazy-lock.json" ]] && ok "lazy-lock.json present (pinned plugins)"
  ok "Config installed at $NVIM_CONFIG"
}

build_native_plugins() {
  local fzf_dir="$LAZY_ROOT/telescope-fzf-native.nvim"
  local avante_dir="$LAZY_ROOT/avante.nvim"

  if [[ -d "$fzf_dir" ]]; then
    info "Building telescope-fzf-native..."
    (cd "$fzf_dir" && make) && ok "telescope-fzf-native built" \
      || warn "telescope-fzf-native build failed (Telescope still works without it)"
  fi

  if [[ -d "$avante_dir" ]]; then
    info "Building avante.nvim..."
    (cd "$avante_dir" && make) && ok "avante.nvim built" \
      || warn "avante.nvim build failed — open nvim and run :Lazy build avante.nvim"
  fi
}

sync_plugins() {
  if [[ "$NO_SYNC" -eq 1 ]]; then
    info "Skipping Lazy sync (--no-sync)"
    return
  fi

  have nvim || fail "nvim not found"

  info "Syncing lazy.nvim plugins (headless)..."
  # Install lazy.nvim if missing, then sync + build
  nvim --headless \
    "+Lazy! sync" \
    "+Lazy! build" \
    "+qa" 2>&1 || {
    warn "Headless Lazy sync reported errors. Open nvim and run :Lazy sync"
  }

  build_native_plugins
  ok "Plugins synced"
}

check_tool() {
  local name="$1"
  if have "$name"; then
    printf '  \033[1;32m✓\033[0m %-14s %s\n' "$name" "$(command -v "$name")"
  else
    printf '  \033[1;33m!\033[0m %-14s missing\n' "$name"
  fi
}

health_check() {
  info "Health check"
  check_tool nvim
  check_tool git
  check_tool rg
  check_tool fd
  check_tool node
  check_tool make
  check_tool cmake
  check_tool rustc
  check_tool cargo
  check_tool rust-analyzer
  check_tool stylua
  check_tool black
  check_tool prettier
  check_tool ruff
  check_tool eslint_d
  check_tool hadolint
  check_tool agent

  if [[ -f "$NVIM_CONFIG/init.lua" ]]; then
    ok "init.lua → $NVIM_CONFIG/init.lua"
  else
    warn "init.lua not found at $NVIM_CONFIG"
  fi

  if [[ -d "$LAZY_ROOT" ]]; then
    local count
    count="$(find "$LAZY_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    ok "lazy plugins directory: $count plugins in $LAZY_ROOT"
  else
    warn "lazy plugins not installed yet (open nvim once)"
  fi
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

  Set your terminal font to a Nerd Font (e.g. JetBrainsMono Nerd Font)
  so icons render correctly.

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
  health_check
  print_next_steps
}

main "$@"
