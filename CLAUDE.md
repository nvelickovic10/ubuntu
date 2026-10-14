# Ubuntu setup repo

Personal Ubuntu tooling and setup notes (remote: `github.com/nvelickovic10/ubuntu`, branch `master`). `bin/` is on `PATH`, so the `nv-*` scripts run by name.

- `bin/` — `nv-*` helper scripts. `bin/common/` holds the shared shell libs they source (`common.sh`, `sudoUtil.sh`, `arrayUtil.sh`).
- `system-notes/` — notes on system-level changes on this machine (Serbian), indexed by `system-notes/README.md`. Update the relevant note after each system-level change, using the `system-notes` skill.
- `Passwords.kdbx` is a KeePass database: never read or modify it.

Don't commit or push unless asked.

## Script conventions

Scripts start with `SCRIPT_DESC=...`, set `commons_dir` relative to the script (`$(dirname "${BASH_SOURCE[0]}")/common`), then source `common.sh`, and `sudoUtil.sh` only if they need sudo. `common.sh` logs start/finish with runtime and "Reboot required" through an EXIT trap; `logInfo`/`logError`/`logDebug` are the logging helpers. `sudoUtil.sh` pre-authenticates sudo when sourced and provides `runAsSudo "<command string>"` (runs `sudo bash -c`), so privileged commands are passed as one string.

## Per-script docs

Usage, behavior and gotchas of each `nv-*` script are in the comment header at the top of the script itself. Read it before changing a script, and update it with the change.
