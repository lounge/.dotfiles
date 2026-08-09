#!/usr/bin/env bash
#
# Bootstrap a new macOS machine: install tools, then symlink the configs in
# this repo into their live locations. Safe to re-run — existing installs are
# skipped and any real file in the way of a symlink is moved to a backup dir.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
skip()  { printf '    %s\n' "$*"; }

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

# --- Homebrew -----------------------------------------------------------------
if ! command -v brew >/dev/null; then
  info "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Make brew available in this script on a fresh machine
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

info "Installing brew packages"
brew list tmux >/dev/null 2>&1 || brew install tmux
brew list fnm  >/dev/null 2>&1 || brew install fnm
brew list --cask ghostty >/dev/null 2>&1 || brew install --cask ghostty
brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1 || brew install --cask font-jetbrains-mono-nerd-font
brew list --cask rider >/dev/null 2>&1 || brew install --cask rider
brew list --cask dotnet-sdk >/dev/null 2>&1 || brew install --cask dotnet-sdk
brew list --cask zed >/dev/null 2>&1 || brew install --cask zed
brew list --cask fork >/dev/null 2>&1 || brew install --cask fork
brew list --cask docker-desktop >/dev/null 2>&1 || brew install --cask docker-desktop
brew list --cask lm-studio >/dev/null 2>&1 || brew install --cask lm-studio

# MesloLGS NF — the font powerlevel10k and the ghostty config expect
info "Installing MesloLGS NF fonts"
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

# --- Oh My Zsh + powerlevel10k + plugins --------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
info "Installing zsh theme and plugins"
[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || \
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# --- tmux plugin manager ------------------------------------------------------
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  info "Installing tpm (tmux plugin manager)"
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# --- Symlink configs ----------------------------------------------------------
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

info "Linking Claude Code skills"
for skill in "$DOTFILES"/agents/skills/*/; do
  name="$(basename "$skill")"
  link "${skill%/}" "$HOME/.agents/skills/$name"
  link "$HOME/.agents/skills/$name" "$HOME/.claude/skills/$name"
done

# tmux plugins declared in .tmux.conf (needs the conf symlinked first)
info "Installing tmux plugins"
"$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null || true

echo
info "Done."
skip "Rider settings are not automated: import $DOTFILES/rider/settings.zip via Rider > Manage Settings > Import."
[ -d "$BACKUP_DIR" ] && skip "Replaced files were backed up to $BACKUP_DIR"
skip "Open a new terminal (or run: exec zsh) to pick up the new config."
