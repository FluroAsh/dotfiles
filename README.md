# dotfiles

Terminal config shared between my machines.

| Path | Tool | Linked to |
| --- | --- | --- |
| `ghostty/config.ghostty` | [Ghostty](https://ghostty.org) | `~/.config/ghostty/config.ghostty` |
| `ghostty/themes/*` | Ghostty custom themes (Gruvbox Sepia Light/Dark) | `~/.config/ghostty/themes/` |
| `herdr/config.toml` | Herdr | `~/.config/herdr/config.toml` |
| `cursor/*` | Cursor settings and keybindings | copy or link manually (not handled by `install.sh`) |

## Set up a new machine

```sh
git clone https://github.com/<user>/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

The script symlinks each file into place and backs up anything already there
as `<file>.bak.<timestamp>`. Re-running it is safe. Edit the files in this repo
(or through the symlinks), then commit and push.

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
