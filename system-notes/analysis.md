# Analize

## Potrošnja baterije (merenja 2026-10-09/10)

Posle PowerTOP podešavanja i gašenja `macfanctld` (vidi [macbook-setup.md](macbook-setup.md)): pod opterećenjem 15,8–28 W (prosek ~21,6 W), u mirovanju sa uključenim ekranom ~13–14,5 W. Package C-stanja (PC6) nikad ne ulaze u duboko spavanje; to je najveći gubitak, ali dalja analiza (ASPM, Thunderbolt, xHCI) zatvorena je po odluci korisnika. Gašenje `gpe17` ne pomaže (`acpi_mask_gpe=0x17` nije potreban), a SATA ALPM Apple AHCI ne podržava. Provera posle punjenja (2026-10-10): baterija 107 Wh od 99,99 Wh, 142 ciklusa, bez problema.

Merenje: root petlja pravi PowerTOP CSV na 30 s: `sudo -b sh -c 'while true; do powertop --time=30 --csv=/tmp/powertop.tmp >/dev/null 2>&1 && chmod 644 /tmp/powertop.tmp && mv /tmp/powertop.tmp /tmp/powertop.csv; done'`; gašenje `sudo pkill -f 'while true; do powertop'; sudo pkill powertop`.

## Trajanje boota

Trenutno **14,2 s** (2,0 s kernel + 12,2 s userspace; pre izmene 23,6 s). Uzrok je bio `gpu-manager.service` (10,4 s): čekao je NVIDIA udev pravila koja nikad ne stižu, a `gdm.service` ima `After=gpu-manager.service`. Najsporije je sada `gdm.service` (5,1 s), pa `snapd` (~2,5 s), sve paralelno.

- Mera: `gpu-manager.service` maskiran (vidi „Isključeni servisi“ u `macbook-setup.md`).

## Instalirani softver (popis 2026-10-13; Ubuntu 26.04.1, kernel 7.0.0-38)

**apt (ručno instalirano):**
- Razvoj: `git`, `build-essential`, `gcc`, `g++`, `nasm`, `pkg-config`, `checkinstall`, `dkms`, `code` (.deb), `openjdk-17-jdk-headless`, `python-is-python3`, `pipx`, `docker-ce` + `containerd.io`, `mongodb-mongosh`, `pgadmin4-desktop`, `xvfb`, `adb`
- Hardver i sistem: `broadcom-sta-dkms`, `mbpfan`, `lm-sensors`, `powertop`, `intel-gpu-tools`, `vainfo`, `mesa-utils`, `efibootmgr`, `gparted`, `kyocera-sane`, `stress`, `systemd-zram-generator`, `zenity`
- Aplikacije: `google-chrome-stable`, `vlc`, `transmission`, `copyq`, `imagemagick`, `simple-scan`, `htop`, `autojump`, `screen`, `curl`
- Ostalo: `ibus-table-cangjie*`, `xfonts-cyrillic`, `xfonts-scalable`, `wbritish`

**Snap:** ručno `cheese`, `remmina`, `solvespace` (ostaju namerno); ostalo uz sistem. Flatpak nije instaliran.

**Van paketnih menadžera:** `/usr/local/bin` (`go`, `kubectl`, `helm`, `nosqlbooster4mongo`, `frontProxy`, `lowjson`; uz njih `go.new`, `helm3.15.2`, `kubectl1.30`), `~/.local/bin` (`claude`), `~/go/bin` (`gopls`, `golangci-lint`, `staticcheck`), npm globalno (`typescript`, `ts-node`), `~/.nvm`, `~/Android/Sdk`. Python je samo sistemski `python3.14`.

**apt repozitorijumi** (`resolute`): `ubuntu.sources`, `ubuntu-esm-apps`, `ubuntu-esm-infra`, `google-chrome`, `vscode`, `docker.sources`, `pgadmin4.sources`.

Ponavljanje popisa: `apt-mark showmanual; snap list; apt list --installed 2>/dev/null | grep ',local\]'; ls /usr/local/bin /opt ~/.local/bin ~/go/bin`.
