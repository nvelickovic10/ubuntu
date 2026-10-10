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

Only `--all` passes `-y` (variable `ASSUME_YES`). It used to pipe `yes` into each step and hung; the suspected cause is the pipe on stdin combined with `sudo-rs` (Ubuntu's current `sudo`), not confirmed because the fix was never run with real sudo. `yes` also cannot answer prompts other than y/n. Don't reintroduce `yes |` or `eval` pipelines. Pass flags to apt through `ASSUME_YES`, and keep each action a separate `fn_*` function selected by the `ACTION` variable.

## nv-root-clean

Frees disk space by removing unused container data and old snap revisions. Takes no options.

1. `docker system prune --all --force` — runs as the current user (no sudo) and deletes all stopped containers, unused networks, build cache and **every image not used by a container**. On this machine that includes the `antenator-nec2-server` image whenever no container uses it, so it has to be pulled or rebuilt afterwards.
2. `snap list --all` is filtered for `disabled` entries (old revisions kept by snap), and each one is removed with `runAsSudo "snap remove <name> --revision=<rev> < /dev/null"`. Active revisions are untouched. The `< /dev/null` keeps the command from swallowing the rest of the list read by the `while read` loop.

Note: `set -eu` is enabled only after the docker step, so a docker failure does not stop the script but a failing snap removal does.
