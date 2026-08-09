#!/usr/bin/env bash
#
# Bootstrap a macOS machine: install tools, then symlink the configs in this
# repo into their live locations. Safe to re-run — existing installs are
# skipped and any real file in the way of a symlink is moved to a backup dir.
#
# Usage: ./install.sh [app] [cli] [lang] [misc] [conf] [link]
#   app   dev GUI applications (ghostty, rider, zed, fork, docker, postman, ...)
#   cli   command-line tools (tmux, gh, azure-cli, mkcert, ngrok, claude)
#   lang  language toolchains (fnm/node, dotnet, aspire, go, rust, odin)
#   misc  non-dev apps (brave, discord, telegram)
#   conf  shell stack (oh-my-zsh, powerlevel10k, zsh plugins, tpm, fonts)
#   link  symlink repo configs and Claude skills into place (offline, no brew)
# No arguments = install everything.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
skip()  { printf '    %s\n' "$*"; }

usage() { sed -n '/^# Usage/,/^# No arguments/s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }

# --- Category selection -------------------------------------------------------
DO_APP=false DO_CLI=false DO_LANG=false DO_MISC=false DO_CONF=false DO_LINK=false
if [ $# -eq 0 ]; then
  DO_APP=true DO_CLI=true DO_LANG=true DO_MISC=true DO_CONF=true DO_LINK=true
else
  for arg in "$@"; do
    case "$arg" in
      app|apps)     DO_APP=true ;;
      cli)          DO_CLI=true ;;
      lang|langs)   DO_LANG=true ;;
      misc)         DO_MISC=true ;;
      conf|config)  DO_CONF=true ;;
      link|links)   DO_LINK=true ;;
      -h|--help)    usage; exit 0 ;;
      *)            echo "Unknown category: $arg"; usage; exit 1 ;;
    esac
  done
fi

# --- Helpers ------------------------------------------------------------------
ensure_brew() {
  if ! command -v brew >/dev/null; then
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Make brew available in this script on a fresh machine
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  return 0
}

bi() { brew list "$1" >/dev/null 2>&1 || brew install "$1"; }
bc() { brew list --cask "$1" >/dev/null 2>&1 || brew install --cask "$1"; }

# Symlink $1 (repo path) to $2 (live path), backing up whatever is there.
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    skip "$dst already linked"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/"
    skip "backed up existing $dst to $BACKUP_DIR/"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  skip "$dst -> $src"
}

# --- app: dev GUI applications ------------------------------------------------
install_app() {
  info "Installing dev apps"
  ensure_brew
  local casks=(
    ghostty rider zed fork
    docker-desktop lm-studio postman
  )
  for c in "${casks[@]}"; do bc "$c"; done
  skip "Rider settings are not automated: import $DOTFILES/rider/settings.zip via Rider > Manage Settings > Import."
}

# --- cli: command-line tools --------------------------------------------------
install_cli() {
  info "Installing CLI tools"
  ensure_brew
  local formulae=(tmux gh azure-cli mkcert)
  for f in "${formulae[@]}"; do bi "$f"; done
  bc ngrok

  # Claude Code via native installer (self-updating, lands in ~/.local/bin)
  if ! command -v claude >/dev/null; then
    info "Installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
  fi
}

# --- lang: language toolchains ------------------------------------------------
install_lang() {
  info "Installing language toolchains"
  ensure_brew
  local formulae=(fnm go golangci-lint odin odinfmt)
  for f in "${formulae[@]}"; do bi "$f"; done
  bc dotnet-sdk
  bc aspire

  # Rust via rustup (zshrc sources ~/.cargo/env when present)
  if [ ! -d "$HOME/.cargo" ]; then
    info "Installing Rust (rustup)"
    curl --proto '=https' --tlsv1.2 -fsSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  fi
}

# --- misc: non-dev apps -------------------------------------------------------
install_misc() {
  info "Installing misc apps"
  ensure_brew
  local casks=(brave-browser discord telegram)
  for c in "${casks[@]}"; do bc "$c"; done
}

# --- conf: shell stack --------------------------------------------------------
install_conf() {
  info "Installing fonts"
  ensure_brew
  bc font-jetbrains-mono-nerd-font
  # MesloLGS NF — the font powerlevel10k and the ghostty config expect
  local style font
  for style in Regular Bold Italic "Bold Italic"; do
    font="MesloLGS NF ${style}.ttf"
    if [ ! -f "$HOME/Library/Fonts/$font" ]; then
      curl -fsSL -o "$HOME/Library/Fonts/$font" \
        "https://github.com/romkatv/powerlevel10k-media/raw/master/${font// /%20}"
      skip "installed $font"
    else
      skip "$font already installed"
    fi
  done

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  info "Installing zsh theme and plugins"
  [ -d "$zsh_custom/themes/powerlevel10k" ] || \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k"
  [ -d "$zsh_custom/plugins/zsh-autosuggestions" ] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$zsh_custom/plugins/zsh-autosuggestions"
  [ -d "$zsh_custom/plugins/zsh-syntax-highlighting" ] || \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"

  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "Installing tpm (tmux plugin manager)"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi
}

# --- link: symlink configs and skills -----------------------------------------
install_link() {
  # Workspace layout the git includeIf identity switching relies on
  info "Creating workspace directories"
  mkdir -p "$HOME/workspace/personal" "$HOME/workspace/work"

  info "Linking configs"
  link "$DOTFILES/zsh/.zshrc"      "$HOME/.zshrc"
  link "$DOTFILES/zsh/.p10k.zsh"   "$HOME/.p10k.zsh"
  link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"
  link "$DOTFILES/git/.gitconfig"          "$HOME/.gitconfig"
  link "$DOTFILES/git/.gitconfig-personal" "$HOME/.gitconfig-personal"
  link "$DOTFILES/git/.gitconfig-work"     "$HOME/.gitconfig-work"
  link "$DOTFILES/ghostty/config"  "$HOME/.config/ghostty/config"
  # Only settings.json is tracked — the rest of ~/.config/zed is Zed-internal state
  link "$DOTFILES/zed/settings.json" "$HOME/.config/zed/settings.json"
  # Same for ~/.claude — settings.json only (model, plugins/marketplaces), rest is runtime state
  link "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"

  info "Linking Claude Code skills"
  local skill name
  for skill in "$DOTFILES"/agents/skills/*/; do
    name="$(basename "$skill")"
    link "${skill%/}" "$HOME/.agents/skills/$name"
    link "$HOME/.agents/skills/$name" "$HOME/.claude/skills/$name"
  done

  # tmux plugins declared in .tmux.conf (needs the conf symlinked first)
  if command -v tmux >/dev/null && [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    info "Installing tmux plugins"
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null || true
  else
    skip "tmux or tpm missing — run './install.sh cli conf' then re-run link to install tmux plugins"
  fi
}

# --- Run selected categories --------------------------------------------------
$DO_CLI  && install_cli
$DO_LANG && install_lang
$DO_APP  && install_app
$DO_MISC && install_misc
$DO_CONF && install_conf
$DO_LINK && install_link

echo
info "Done."
[ -d "$BACKUP_DIR" ] && skip "Replaced files were backed up to $BACKUP_DIR"
{ $DO_CONF || $DO_LINK; } && skip "Open a new terminal (or run: exec zsh) to pick up the new config."
exit 0
