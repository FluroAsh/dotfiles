# dotfiles

Terminal and editor config shared between my machines.

| Path | Tool | Linked to |
| --- | --- | --- |
| `ghostty/config.ghostty` | [Ghostty](https://ghostty.org) | `~/.config/ghostty/config.ghostty` |
| `ghostty/themes/*` | Ghostty custom themes (Gruvbox Sepia Light/Dark) | `~/.config/ghostty/themes/` |
| `herdr/config.toml` | Herdr | `~/.config/herdr/config.toml` |
| `zed/settings.json` | [Zed](https://zed.dev) settings | `~/.config/zed/settings.json` |
| `zed/keymap.json` | Zed key bindings | `~/.config/zed/keymap.json` |
| `zed/sync-extensions.sh` | Zed extension sync (see below) | Run by a LaunchAgent, `~/Library/LaunchAgents/dotfiles.zed-extensions.plist` |

## Set up a new machine

```sh
git clone https://github.com/FluroAsh/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

Everything is enabled by default. In a terminal, `install.sh` runs a short
wizard that asks about each tool with something left to link (Enter accepts
the default), so you can opt out of the ones you don't want on a given
machine. Tools that are already fully linked aren't asked about again.

| Command | Effect |
| --- | --- |
| `./install.sh` | Wizard: asks about each unlinked tool, default yes |
| `./install.sh --yes` | No prompts: install everything (or your saved choices) |
| `./install.sh --skip herdr` | Skip the listed tools |
| `./install.sh --only ghostty` | Install only the listed tools |
| `./install.sh --dry-run` | Show what would be linked, change nothing |
| `./install.sh --list` | List the tools |

The script symlinks each file into place and backs up anything already there
as `<file>.bak.<timestamp>`. A file that's byte-for-byte identical to the repo
copy is replaced without a backup. Re-running it is safe. Your choices are
saved to `~/.config/dotfiles/choices` (outside the repo) and become the
wizard's defaults next time. Skipping a tool never removes a link made earlier.

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

## Zed extensions

Extensions (themes included) stay in step 1:1 between machines through the
`auto_install_extensions` list in `zed/settings.json`. Install and uninstall
in Zed as usual; don't edit the list by hand.

- **Installing or uninstalling on a machine** updates the list straight away.
  `install.sh` sets up a LaunchAgent that watches Zed's extensions folder and
  runs `zed/sync-extensions.sh export` when it changes. Nothing runs in
  between. Commit and push the change to `settings.json`.
- **After a pull**, run `./install.sh`. Zed only reads the list at startup,
  so when extensions are missing or need removing, the script quits Zed (a
  normal quit, the same as ⌘Q), applies the changes and reopens it. Extensions uninstalled elsewhere are listed first and
  it asks before removing them (answer `n` to keep them and list them again).
  If Zed won't quit, for example because a dialog is open, it says so and
  changes nothing.
- The first run on a machine adds its extensions to the list and removes
  nothing. Dev extensions (symlinked local checkouts) are ignored.
- `zed/sync-extensions.sh status` shows what differs; the agent logs to
  `~/.config/dotfiles/zed-extensions.log`.
- The watcher is macOS-only. On Linux, run `zed/sync-extensions.sh export`
  after changing extensions.

## Notes

- Herdr's logs, sockets and session snapshots are runtime state and are
  git-ignored; only `config.toml` is tracked.
- Zed's `prompts/` (a local database) stays out of the repo; only
  `settings.json` and `keymap.json` are tracked. Changes made in Zed's
  settings UI write through the symlink into this repo.
- Zed's edit predictions point at a local Ollama (`localhost:11435`,
  `qwen2.5-coder:7b`). On a machine without it, predictions just don't load.
- Ghostty's JetBrains Mono font is bundled with Ghostty, nothing to install.
- Ghostty on macOS also reads `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`.
  This repo uses the XDG path only, so delete the Library one if it exists.
