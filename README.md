# dotfiles

[![Install](https://github.com/lounge/.dotfiles/actions/workflows/install.yml/badge.svg)](https://github.com/lounge/.dotfiles/actions/workflows/install.yml)

Personal macOS setup — tools, apps, and configs. Idempotent: re-run anytime, replaced files are backed up to `~/.dotfiles-backup-<timestamp>/`.

## Install

```sh
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles
./install.sh                     # everything
./install.sh cli lang            # whole categories
./install.sh lang:node,dotnet    # specific items from a category
./install.sh app:zed cli link    # mix and match
```

## Categories and items

| Category | Item | Installs |
|---|---|---|
| `app`  | `ghostty` | Ghostty terminal |
|        | `rider` | JetBrains Rider |
|        | `zed` | Zed |
|        | `fork` | Fork git client |
|        | `docker` | Docker Desktop |
|        | `lmstudio` | LM Studio |
|        | `postman` | Postman |
| `cli`  | `git` | git (brew, newer than Apple's) |
|        | `tmux` | tmux |
|        | `gh` | GitHub CLI |
|        | `az` | Azure CLI |
|        | `mkcert` | mkcert |
|        | `ngrok` | ngrok |
|        | `claude` | Claude Code (native installer) |
|        | `herdr` | herdr (native installer) |
|        | `opencode` | opencode (native installer) |
|        | `smtp4dev` | smtp4dev (dotnet global tool) |
| `lang` | `node` | fnm + Node LTS |
|        | `dotnet` | .NET SDK (latest) |
|        | `aspire` | Aspire CLI |
|        | `go` | Go + golangci-lint |
|        | `rust` | Rust via rustup |
|        | `odin` | Odin + odinfmt |
| `misc` | `brave` | Brave Browser |
|        | `discord` | Discord |
|        | `telegram` | Telegram |
| `conf` | `fonts` | JetBrainsMono Nerd Font + MesloLGS NF |
|        | `zsh` | oh-my-zsh + powerlevel10k + zsh plugins |
|        | `tmux` | tpm (tmux plugin manager) |
| `link` | `zsh` | `.zshrc` + `.p10k.zsh` |
|        | `tmux` | `.tmux.conf` + tmux plugins |
|        | `git` | gitconfigs |
|        | `ghostty` | ghostty config |
|        | `zed` | zed settings |
|        | `claude` | claude settings + global `CLAUDE.md` |
|        | `herdr` | herdr config |
|        | `opencode` | opencode config |
|        | `ngrok` | ngrok config (endpoints only, token via `~/.zshrc.local`) |
|        | `skills` | Claude Code skills |

`category` alone = all its items. No arguments = everything. `link` needs no brew (network only to fetch missing tmux plugins).

## What gets linked

| Repo | Live location |
|---|---|
| `zsh/.zshrc`, `zsh/.p10k.zsh` | `~/.zshrc`, `~/.p10k.zsh` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `git/.gitconfig{,-personal,-work}` | `~/` — identity switches per workspace via `includeIf` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `zed/settings.json` | `~/.config/zed/settings.json` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` — global instructions for every project |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `opencode/opencode.json` | `~/.config/opencode/opencode.json` |
| `ngrok/ngrok.yml` | `~/Library/Application Support/ngrok/ngrok.yml` |
| `agents/skills/*` | `~/.agents/skills/*` + `~/.claude/skills/*` |

Symlinks mean edits in the repo apply immediately — just commit when done.

## Manual steps

- Secrets live in `~/.zshrc.local` (untracked, sourced by `.zshrc`). ngrok needs `export NGROK_AUTHTOKEN=<token>` there — the tracked `ngrok.yml` has no token.
- Rider: import `rider/settings.zip` via **Manage Settings → Import**.
- LM Studio CLI (`lms`): launch the app once to bootstrap it.
- herdr: the `hooks` block in `claude/settings.json` and `~/.claude/hooks/herdr-agent-state.sh` are written by `herdr integration`, not by hand. On a fresh machine the hook fails harmlessly at Claude Code startup until that integration is installed.

## CI

`.github/workflows/install.yml` runs `./install.sh cli lang conf link` on a macOS runner, runs it again to check idempotency, then verifies the symlinks and that every tool is on PATH in zsh. `app` and `misc` are not installed (multi-GB GUI casks); a separate job resolves each of their cask download URLs and checks it is reachable without downloading.
