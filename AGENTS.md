# AGENTS.md

Personal dotfiles shared between machines: Ghostty and Herdr config,
plus `install.sh` to symlink them into place. See `README.md` for layout and
setup.

## Public repo: no personal data

This repository is public.

- **Never hard-code secrets**: tokens, API keys, passwords, private keys or
  credentials of any kind. Always inject them via environment variables set by
  the shell (profile, keychain or secrets manager), and reference the variable
  name, never the value. If a tool only accepts a literal value in its config
  file, leave that setting out of the repo and configure it locally.
- Do not paste a secret into a command, a commit message, a file or the chat.
  If you find one in the repo or its history, stop and tell the user so it can
  be revoked before anything is rewritten.
- Don't add employer details, internal hostnames or work email addresses.

## Git identity and pushing

- Commits use the repo-local git identity, already configured to the personal
  GitHub account's `noreply` address. Never override it with the global (work)
  identity and never use a work GitHub account or work SSH key for this repo.
- Authenticate pushes through `gh`'s stored login for the personal account,
  passed per command via `GH_TOKEN` from `gh auth token --user <personal>`.
  The shell's `GITHUB_TOKEN` belongs to the work account, so unset or override
  it for these commands. Keep the remote as a plain HTTPS URL with no token in it.
- Confirm the author, committer and pushing account before pushing.

## Working in this repo

- Edit the files here, not the symlinked copies elsewhere, then commit and push.
- Keep `install.sh` idempotent: it must back up existing files and be safe to re-run.
- Every tool is enabled by default and can be opted out through the wizard or
  `--skip`/`--only`. To add a tool, add a line to `TOOLS` and an `install_<name>`
  function in `install.sh`, then list it in the README tables. The script must
  stay compatible with macOS's bash 3.2 (no associative arrays).
- Runtime state (Herdr logs, sockets, session snapshots) stays out of git.
- Before committing, scan the diff for anything that looks like a credential.
