# Ubuntu setup repo

Personal Ubuntu tooling and setup notes (remote: `github.com/nvelickovic10/ubuntu`, branch `master`). `bin/` is on `PATH`, so the `nv-*` scripts run by name.

- `bin/` — `nv-*` helper scripts. `bin/common/` holds the shared shell libs they source (`common.sh`, `sudoUtil.sh`, `arrayUtil.sh`).
- `system-notes/` — notes on system-level changes on this machine (Serbian), indexed by `system-notes/README.md`. Update the relevant note after each system-level change.
- `commandsold.txt`, `tips and tricks.txt` — old setup notes (2024).
- `Passwords.kdbx` is a KeePass database: never read or modify it.

Don't commit or push unless asked. System-level changes on this machine are documented in `system-notes/` (imported below), not in the script notes.

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

## nv-hibernate

`nv-hibernate on|off` turns hibernation on or off as a whole. Needs sudo (sources `sudoUtil.sh`).

- `off`: disables the `hibernate-menu@local` GNOME extension (hides the power menu item), deletes `/etc/default/grub.d/90-resume.cfg` and `/etc/initramfs-tools/conf.d/resume`, recreates `/swap.img` as 4G (`swapoff`, `rm`, `fallocate`, `mkswap`, `swapon`), then `update-initramfs -u -k all && update-grub`.
- `on`: recreates `/swap.img` as 20G, reads `resume_offset` from the first extent of `sudo filefrag -v /swap.img`, writes both resume configs with the root UUID and that offset (the grub one replaces `GRUB_CMDLINE_LINUX_DEFAULT` with `quiet splash resume=... resume_offset=...`), rebuilds initramfs/grub, writes the offset to `/sys/power/resume_offset` of the running kernel, enables the extension.
- Both are idempotent for the swap size (skipped if the file already has the target size). The runtime write to `/sys/power/resume_offset` is needed because logind reports `CanHibernate=na` while the running kernel's offset differs from the swap file's; the new command line itself only applies after a reboot.
- The offset changes every time `/swap.img` is recreated, which is why the resume config is rewritten on `on` and dropped on `off`. Don't recreate the swap file elsewhere without redoing it.

## nv-turbo

`nv-turbo on|off` enables or disables Intel Turbo Boost by writing `0` / `1` to `/sys/devices/system/cpu/intel_pstate/no_turbo` through `runAsSudo`, then logs the resulting state. The setting lasts until reboot. It replaces the `nv-turbo-on` / `nv-turbo-off` aliases that used to live in `~/.bash_aliases` (removed).

## System notes

@system-notes/README.md
@system-notes/macbook-setup.md
@system-notes/analysis.md
@system-notes/extensions.md
