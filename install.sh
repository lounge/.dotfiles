#!/usr/bin/env bash
#
# Bootstrap a macOS machine: install tools, then symlink the configs in this
# repo into their live locations. Safe to re-run — existing installs are
# skipped and any real file in the way of a symlink is moved to a backup dir.
#
# Usage: ./install.sh [category[:item,item...]] ...
#   app   dev GUI apps      (ghostty rider zed fork docker lmstudio postman)
#   cli   command-line tools (git tmux gh az mkcert ngrok claude herdr)
#   lang  language toolchains (node dotnet aspire go rust odin)
#   misc  non-dev apps       (brave discord telegram)
#   conf  shell stack        (fonts zsh tmux)
#   link  config symlinks    (zsh tmux git ghostty zed claude herdr skills)
# Examples:
#   ./install.sh                     everything
#   ./install.sh lang                all of lang
#   ./install.sh lang:node,dotnet    only node + dotnet
#   ./install.sh app:zed cli link    mix and match
# No arguments = install everything.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
skip()  { printf '    %s\n' "$*"; }

usage() { sed -n '/^# Usage/,/^# No arguments/s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }

# --- Category selection -------------------------------------------------------
APP_KNOWN="ghostty rider zed fork docker lmstudio postman"
CLI_KNOWN="git tmux gh az mkcert ngrok claude herdr"
LANG_KNOWN="node dotnet aspire go rust odin"
MISC_KNOWN="brave discord telegram"
CONF_KNOWN="fonts zsh tmux"
LINK_KNOWN="zsh tmux git ghostty zed claude herdr skills"

DO_APP=false  APP_ITEMS=""
DO_CLI=false  CLI_ITEMS=""
DO_LANG=false LANG_ITEMS=""
DO_MISC=false MISC_ITEMS=""
DO_CONF=false CONF_ITEMS=""
DO_LINK=false LINK_ITEMS=""

validate_items() { # $1=known items  $2=comma list  $3=category name
  local i
  for i in ${2//,/ }; do
    case " $1 " in
      *" $i "*) ;;
      *) echo "Unknown $3 item: $i"; echo "Valid $3 items: $1"; exit 1 ;;
    esac
  done
}

# Sets DO_<cat>=true and merges items ("all" when the bare category is given)
select_cat() { # $1=flag var  $2=items var  $3=known items  $4=cat name  $5=comma list or ""
  printf -v "$1" true
  if [ -z "$5" ]; then
    printf -v "$2" all
  elif [ "${!2}" != "all" ]; then
    validate_items "$3" "$5" "$4"
    printf -v "$2" '%s' "${!2:+${!2},}$5"
  fi
}

if [ $# -eq 0 ]; then
  DO_APP=true APP_ITEMS=all DO_CLI=true CLI_ITEMS=all DO_LANG=true LANG_ITEMS=all
  DO_MISC=true MISC_ITEMS=all DO_CONF=true CONF_ITEMS=all DO_LINK=true LINK_ITEMS=all
else
  for arg in "$@"; do
    cat="${arg%%:*}"
    items=""; [ "$arg" != "$cat" ] && items="${arg#*:}"
    case "$cat" in
      app|apps)     select_cat DO_APP  APP_ITEMS  "$APP_KNOWN"  app  "$items" ;;
      cli)          select_cat DO_CLI  CLI_ITEMS  "$CLI_KNOWN"  cli  "$items" ;;
      lang|langs)   select_cat DO_LANG LANG_ITEMS "$LANG_KNOWN" lang "$items" ;;
      misc)         select_cat DO_MISC MISC_ITEMS "$MISC_KNOWN" misc "$items" ;;
      conf|config)  select_cat DO_CONF CONF_ITEMS "$CONF_KNOWN" conf "$items" ;;
      link|links)   select_cat DO_LINK LINK_ITEMS "$LINK_KNOWN" link "$items" ;;
      -h|--help)    usage; exit 0 ;;
      *)            echo "Unknown category: $cat"; usage; exit 1 ;;
    esac
  done
fi

# True when the item list is "all" or contains the item
want() { # $1=items  $2=item
  [ "$1" = "all" ] && return 0
  case ",$1," in *",$2,"*) return 0 ;; *) return 1 ;; esac
}

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
  want "$APP_ITEMS" ghostty  && bc ghostty
  want "$APP_ITEMS" rider    && bc rider
  want "$APP_ITEMS" zed      && bc zed
  want "$APP_ITEMS" fork     && bc fork
  want "$APP_ITEMS" docker   && bc docker-desktop
  want "$APP_ITEMS" lmstudio && bc lm-studio
  want "$APP_ITEMS" postman  && bc postman
  if want "$APP_ITEMS" rider; then
    skip "Rider settings are not automated: import $DOTFILES/rider/settings.zip via Rider > Manage Settings > Import."
  fi
  return 0
}

# --- cli: command-line tools --------------------------------------------------
install_cli() {
  info "Installing CLI tools"
  ensure_brew
  want "$CLI_ITEMS" git    && bi git
  want "$CLI_ITEMS" tmux   && bi tmux
  want "$CLI_ITEMS" gh     && bi gh
  want "$CLI_ITEMS" az     && bi azure-cli
  want "$CLI_ITEMS" mkcert && bi mkcert
  want "$CLI_ITEMS" ngrok  && bc ngrok

  # Claude Code via native installer (self-updating, lands in ~/.local/bin)
  if want "$CLI_ITEMS" claude && ! command -v claude >/dev/null; then
    info "Installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
  fi

  # herdr via native installer (self-updating with `herdr update`, lands in ~/.local/bin)
  if want "$CLI_ITEMS" herdr && ! command -v herdr >/dev/null; then
    info "Installing herdr"
    curl -fsSL https://herdr.dev/install.sh | sh
  fi
  return 0
}

# --- lang: language toolchains ------------------------------------------------
install_lang() {
  info "Installing language toolchains"
  ensure_brew
  if want "$LANG_ITEMS" node; then
    bi fnm
    # Latest LTS node via fnm if no version is installed yet
    if ! fnm list 2>/dev/null | grep -q 'v[0-9]'; then
      info "Installing Node LTS"
      fnm install --lts
      fnm default lts-latest
    fi
  fi
  if want "$LANG_ITEMS" go; then
    bi go
    bi golangci-lint
  fi
  if want "$LANG_ITEMS" odin; then
    bi odin
    bi odinfmt
  fi
  want "$LANG_ITEMS" dotnet && bc dotnet-sdk
  want "$LANG_ITEMS" aspire && bc aspire

  # Rust via rustup (zshrc sources ~/.cargo/env when present)
  if want "$LANG_ITEMS" rust && [ ! -d "$HOME/.cargo" ]; then
    info "Installing Rust (rustup)"
    curl --proto '=https' --tlsv1.2 -fsSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  fi
  return 0
}

# --- misc: non-dev apps -------------------------------------------------------
install_misc() {
  info "Installing misc apps"
  ensure_brew
  want "$MISC_ITEMS" brave    && bc brave-browser
  want "$MISC_ITEMS" discord  && bc discord
  want "$MISC_ITEMS" telegram && bc telegram
  return 0
}

# --- conf: shell stack --------------------------------------------------------
install_conf() {
  if want "$CONF_ITEMS" fonts; then
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
  fi

  if want "$CONF_ITEMS" zsh; then
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
  fi

  if want "$CONF_ITEMS" tmux && [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "Installing tpm (tmux plugin manager)"
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi
  return 0
}

# --- link: symlink configs and skills -----------------------------------------
install_link() {
  # Workspace layout the git includeIf identity switching relies on
  info "Creating workspace directories"
  mkdir -p "$HOME/workspace/personal" "$HOME/workspace/work"

  info "Linking configs"
  if want "$LINK_ITEMS" zsh; then
    link "$DOTFILES/zsh/.zshrc"    "$HOME/.zshrc"
    link "$DOTFILES/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
  fi
  want "$LINK_ITEMS" tmux && link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"
  if want "$LINK_ITEMS" git; then
    link "$DOTFILES/git/.gitconfig"          "$HOME/.gitconfig"
    link "$DOTFILES/git/.gitconfig-personal" "$HOME/.gitconfig-personal"
    link "$DOTFILES/git/.gitconfig-work"     "$HOME/.gitconfig-work"
  fi
  want "$LINK_ITEMS" ghostty && link "$DOTFILES/ghostty/config" "$HOME/.config/ghostty/config"
  # Only settings.json is tracked — the rest of ~/.config/zed is Zed-internal state
  want "$LINK_ITEMS" zed && link "$DOTFILES/zed/settings.json" "$HOME/.config/zed/settings.json"
  # Same for ~/.claude — settings.json only (model, plugins/marketplaces), rest is runtime state
  want "$LINK_ITEMS" claude && link "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
  # Same for ~/.config/herdr — config.toml only, the rest is sockets, logs and session state
  want "$LINK_ITEMS" herdr && link "$DOTFILES/herdr/config.toml" "$HOME/.config/herdr/config.toml"

  if want "$LINK_ITEMS" skills; then
    info "Linking Claude Code skills"
    local skill name
    for skill in "$DOTFILES"/agents/skills/*/; do
      name="$(basename "$skill")"
      link "${skill%/}" "$HOME/.agents/skills/$name"
      link "$HOME/.agents/skills/$name" "$HOME/.claude/skills/$name"
    done
  fi

  # tmux plugins declared in .tmux.conf (needs the conf symlinked first)
  if want "$LINK_ITEMS" tmux; then
    if command -v tmux >/dev/null && [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
      info "Installing tmux plugins"
      "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null || true
    else
      skip "tmux or tpm missing — run './install.sh cli:tmux conf:tmux' then re-run link:tmux to install tmux plugins"
    fi
  fi
  return 0
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
