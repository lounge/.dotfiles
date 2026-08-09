# dotfiles

Personal macOS setup — tools, apps, and configs. Idempotent: re-run anytime, replaced files are backed up to `~/.dotfiles-backup-<timestamp>/`.

## Install

```sh
git clone <repo-url> ~/workspace/personal/.dotfiles
cd ~/workspace/personal/.dotfiles
./install.sh              # everything
./install.sh cli lang     # or pick categories
```

## Categories

| Category | Installs |
|---|---|
| `app`  | ghostty, rider, zed, fork, docker-desktop, lm-studio, postman |
| `cli`  | tmux, gh, azure-cli, mkcert, ngrok, claude code |
| `lang` | fnm (node), dotnet-sdk, aspire, go, rust (rustup), odin |
| `misc` | brave, discord, telegram |
| `conf` | oh-my-zsh, powerlevel10k, zsh plugins, tpm, nerd fonts |
| `link` | symlinks configs + Claude skills into place (offline, no brew) |

No arguments = all categories.

## What gets linked

| Repo | Live location |
|---|---|
| `zsh/.zshrc`, `zsh/.p10k.zsh` | `~/.zshrc`, `~/.p10k.zsh` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `git/.gitconfig{,-personal,-work}` | `~/` — identity switches per workspace via `includeIf` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `zed/settings.json` | `~/.config/zed/settings.json` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `agents/skills/*` | `~/.agents/skills/*` + `~/.claude/skills/*` |

Symlinks mean edits in the repo apply immediately — just commit when done.

## Manual steps

- Rider: import `rider/settings.zip` via **Manage Settings → Import**.
- LM Studio CLI (`lms`): launch the app once to bootstrap it.
