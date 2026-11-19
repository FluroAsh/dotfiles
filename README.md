# dotfiles

Terminal and editor config shared between my machines.

| Path | Tool | Linked to |
| --- | --- | --- |
| `ghostty/config.ghostty` | [Ghostty](https://ghostty.org) | `~/.config/ghostty/config.ghostty` |
| `ghostty/themes/*` | Ghostty custom themes (Gruvbox Sepia Light/Dark) | `~/.config/ghostty/themes/` |
| `herdr/config.toml` | Herdr | `~/.config/herdr/config.toml` |
| `cursor/*` | Cursor settings and keybindings | `~/Library/Application Support/Cursor/User/` (macOS) or `~/.config/Cursor/User/` |

## Set up a new machine

```sh
git clone https://github.com/FluroAsh/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

Everything is enabled by default. In a terminal, `install.sh` runs a short
wizard that asks about each tool (Enter accepts the default), so you can opt
out of the ones you don't want on a given machine.

| Command | Effect |
| --- | --- |
| `./install.sh` | Wizard: asks per tool, default yes |
| `./install.sh --yes` | No prompts: install everything (or your saved choices) |
| `./install.sh --skip cursor,herdr` | Skip the listed tools |
| `./install.sh --only ghostty` | Install only the listed tools |
| `./install.sh --dry-run` | Show what would be linked, change nothing |
| `./install.sh --list` | List the tools |

The script symlinks each file into place and backs up anything already there
as `<file>.bak.<timestamp>`. Re-running it is safe. Your choices are saved to
`~/.config/dotfiles/choices` (outside the repo) and become the wizard's
defaults next time. Skipping a tool never removes a link made earlier.

Edit the files in this repo (or through the symlinks), then commit and push.

## Secrets: never commit them

This repo is public. **No token, key, password or other credential goes in any
file here, ever.** Inject them from the shell environment instead.

- Keep secrets in your shell profile or a secrets manager (macOS Keychain,
  1Password CLI, `direnv` with an untracked `.envrc`) and export them as
  environment variables, e.g. `export GITLAB_TOKEN=...`.
- Tools that read an env var (most CLIs, `gh`, `git` credential helpers) pick it
  up from there. Tools that only accept a value in a config file (some editor
  extensions) should be configured locally and left out of this repo.
- If a config in this repo needs a secret, reference the variable name, not the
  value.
- If a secret is ever committed, revoke it immediately; rewriting history does
  not make it safe again.
- `.env` files are git-ignored here as a backstop.

## Notes

- Herdr's logs, sockets and session snapshots are runtime state and are
  git-ignored; only `config.toml` is tracked.
- Ghostty's JetBrains Mono font is bundled with Ghostty, nothing to install.
- Ghostty on macOS also reads `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`.
  This repo uses the XDG path only, so delete the Library one if it exists.
