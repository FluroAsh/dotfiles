# dotfiles

Terminal config shared between my machines.

| Path | Tool | Linked to |
| --- | --- | --- |
| `ghostty/config.ghostty` | [Ghostty](https://ghostty.org) | `~/.config/ghostty/config.ghostty` |
| `ghostty/themes/*` | Ghostty custom themes (Gruvbox Sepia Light/Dark) | `~/.config/ghostty/themes/` |
| `herdr/config.toml` | Herdr | `~/.config/herdr/config.toml` |

## Set up a new machine

```sh
git clone https://github.com/<user>/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

The script symlinks each file into place and backs up anything already there
as `<file>.bak.<timestamp>`. Re-running it is safe. Edit the files in this repo
(or through the symlinks), then commit and push.

## Notes

- Herdr's logs, sockets and session snapshots are runtime state and are
  git-ignored; only `config.toml` is tracked.
- Ghostty's JetBrains Mono font is bundled with Ghostty, nothing to install.
- Ghostty on macOS also reads `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`.
  This repo uses the XDG path only, so delete the Library one if it exists.
