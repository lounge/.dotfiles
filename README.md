# dotfiles

Personal macOS setup — tools, apps, and configs. Idempotent: re-run anytime, replaced files are backed up to `~/.dotfiles-backup-<timestamp>/`.

## Install

```sh
git clone <repo-url> ~/workspace/personal/.dotfiles
cd ~/workspace/personal/.dotfiles
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
| `cli`  | `tmux` | tmux |
|        | `gh` | GitHub CLI |
|        | `az` | Azure CLI |
|        | `mkcert` | mkcert |
|        | `ngrok` | ngrok |
|        | `claude` | Claude Code (native installer) |
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
|        | `claude` | claude settings |
|        | `skills` | Claude Code skills |

`category` alone = all its items. No arguments = everything. `link` is offline, no brew.

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
