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

Only `--all` passes `-y` (variable `ASSUME_YES`). It used to pipe `yes` into each step and hung; the cause was the pipe on stdin combined with `sudo-rs` (Ubuntu's current `sudo`); the fix (`-y` instead of the pipe) has been tested with real sudo and works. `yes` also cannot answer prompts other than y/n. Don't reintroduce `yes |` or `eval` pipelines. Pass flags to apt through `ASSUME_YES`, and keep each action a separate `fn_*` function selected by the `ACTION` variable.

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

## nv-nvidia

`nv-nvidia on|off|status` chooses which GPU drives the internal display from boot (details and the A/B mode table in `system-notes/macbook-setup.md`). Both switches need a reboot; `status` is read-only and compares the running display driver (the GPU of the connected eDP connector) with what is configured for the next boot.

- Both modes write the `gpu-power-prefs` EFI variable as attributes + value with `printf … | tee` (the way that worked on 2026-10-08): `01` = Intel, `00` = NVIDIA (the values `gpu-switch` uses; both confirmed on this machine). Deleting the variable does not work: after a boot it is not listed in efivarfs although the firmware still holds it, and right after a write it exists but reads fail with `Invalid argument` (file size 4) until the next reboot. So the script only checks that the file exists, and `status` judges the mode by the running display (the GPU of the connected eDP connector).
- `on` (NVIDIA, HDMI works): `systemctl disable nvidia-off.service` first (aborts if still enabled), then writes `00`.
- `off` (Intel, NVIDIA powered off): writes `01` first, then `systemctl enable nvidia-off.service`.
- The order is deliberate: the service must never be enabled while NVIDIA drives the display (it would power off a GPU in use; the outcome was not tested), so `on` stops the service first and `off` enables it only after the write. `status` prints an error if the display runs on nouveau while the service is enabled.
- Both modes are idempotent. Both `on` and `off` were confirmed by reboot on 2026-10-13.

## nv-claude-sh

Runs `$XDG_RUNTIME_DIR/run.sh`, the single script Claude Code overwrites for commands the user has to run (see the global CLAUDE.md). Takes no options, prints an error and exits 1 if the file is missing, otherwise exits with the script's own status. It replaces typing `bash $XDG_RUNTIME_DIR/run.sh` by hand.

## nv-live

Runs a script body read from stdin in a maximized GNOME Terminal window (`--maximize`, default profile, outer shell is interactive `bash -ic`; the body itself runs non-interactively), so the output is live (`run.sh` run through the run-preview "Accept" button or `!` only shows output after it finishes). Usage: `nv-live "<title>" <<'EOF' ... EOF`. The body is saved to `$XDG_RUNTIME_DIR/run-body.sh` and run with `bash`, its output goes to the window and is `tee`d to `$XDG_RUNTIME_DIR/run.log`, the exit status to `run.rc`. The window waits for Enter at the end. The inner shell writes its PID to `$XDG_RUNTIME_DIR/run.pid` and `nv-live` polls it (not `gnome-terminal --wait`, which does not notice a closed window reliably): if the window is closed before the body finishes, it returns within ~1 s with exit 130 and "terminal window was closed" (no window within 20 s: exit 1). Otherwise, after it closes, `nv-live` prints the log and exits with the body's status. This is the standard shape of `run.sh` (see the global CLAUDE.md).

## System notes

@system-notes/README.md
@system-notes/macbook-setup.md
@system-notes/analysis.md
@system-notes/extensions.md
@system-notes/claude-config.md
