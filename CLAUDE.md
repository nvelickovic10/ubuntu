# Ubuntu setup repo

Personal Ubuntu tooling and setup notes (remote: `github.com/nvelickovic10/ubuntu`, branch `master`). `bin/` is on `PATH`, so the `nv-*` scripts run by name.

- `bin/` — `nv-*` helper scripts. `bin/common/` holds the shared shell libs they source (`common.sh`, `sudoUtil.sh`, `arrayUtil.sh`).
- `Scripts/` — package listing helpers (`Packages/nv-packages-list-*`).
- `install.txt`, `commandsold.txt`, `tips and tricks.txt` — old setup notes (2024).
- `debs/` — downloaded packages. `Passwords.kdbx` is a KeePass database: never read or modify it.

Don't commit or push unless asked. System-level changes on this machine are documented in `~/system-notes/`, not here.

## Script conventions

Scripts start with `SCRIPT_DESC=...`, set `commons_dir` relative to the script (`$(dirname "${BASH_SOURCE[0]}")/common`), then source `common.sh` and `sudoUtil.sh`. `common.sh` logs start/finish with runtime and "Reboot required" through an EXIT trap; `logInfo`/`logError`/`logDebug` are the logging helpers. `sudoUtil.sh` pre-authenticates sudo when sourced and provides `runAsSudo "<command string>"` (runs `sudo bash -c`), so privileged commands are passed as one string.

## nv-apt

Maintenance wrapper around apt and snap. Usage: `nv-apt [--all | --clean | --update | --upgrade | --status | --switch | --help]`.

| Option | Action |
|---|---|
| `--all`, `--a` (default) | `update`, `dist-upgrade -y`, `autoremove/autoclean/clean -y`, then `snap refresh`, in that order, stopping at the first failure |
| `--update`, `--u` | `apt update && apt list --upgradable` |
| `--upgrade`, `--U` | `apt dist-upgrade` (interactive) |
| `--clean`, `--rm` | `apt autoremove && apt autoclean && apt clean` (interactive) |
| `--status`, `--s` | reports whether the private sources in `PRIVATE_SOURCES` (`tor.list`) are active in `/etc/apt/sources.list.d` ("work settings") or hidden as `.tor.list` ("personal settings") |
| `--switch`, `--S` | toggles those sources by renaming `X.list` ↔ `.X.list`, then runs `--status` |

Only `--all` passes `-y` (variable `ASSUME_YES`). It used to pipe `yes` into each step, which hung under `sudo-rs` (Ubuntu's current `sudo`) and could not answer prompts other than y/n; don't reintroduce `yes |` or `eval` pipelines. Pass flags to apt through `ASSUME_YES`, and keep each action a separate `fn_*` function selected by the `ACTION` variable.
