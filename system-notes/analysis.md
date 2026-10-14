# Analize

Rezultati svih analiza sistema idu u ovaj fajl, svaka u svom `##` odeljku.

## Potrošnja baterije (merenja 2026-10-09/10)

Posle PowerTOP podešavanja i gašenja `macfanctld` (vidi [macbook-setup.md](macbook-setup.md)): pod opterećenjem 15,8–28 W (prosek ~21,6 W), u mirovanju sa uključenim ekranom ~13–14,5 W. Package C-stanja (PC6) nikad ne ulaze u duboko spavanje; to je najveći gubitak, ali dalja analiza (ASPM, Thunderbolt, xHCI) zatvorena je po odluci korisnika. Gašenje `gpe17` ne pomaže (`acpi_mask_gpe=0x17` nije potreban), a SATA ALPM Apple AHCI ne podržava. Provera posle punjenja (2026-10-10): baterija 107 Wh od 99,99 Wh, 142 ciklusa, bez problema.

Merenje: root petlja pravi PowerTOP CSV na 30 s: `sudo -b sh -c 'while true; do powertop --time=30 --csv=/tmp/powertop.tmp >/dev/null 2>&1 && chmod 644 /tmp/powertop.tmp && mv /tmp/powertop.tmp /tmp/powertop.csv; done'`; gašenje `sudo pkill -f 'while true; do powertop'; sudo pkill powertop`.

## Trajanje boota

Trenutno **14,2 s** (2,0 s kernel + 12,2 s userspace; pre izmene 23,6 s). Uzrok je bio `gpu-manager.service` (10,4 s): čekao je NVIDIA udev pravila koja nikad ne stižu, a `gdm.service` ima `After=gpu-manager.service`. Najsporije je sada `gdm.service` (5,1 s), pa `snapd` (~2,5 s), sve paralelno.

- `sudo systemctl mask gpu-manager.service`; vraćanje `sudo systemctl unmask gpu-manager.service`.

## Instalirani softver (popis 2026-10-13; Ubuntu 26.04.1, kernel 7.0.0-38)

**apt (ručno instalirano):**
- Razvoj: `git`, `build-essential`, `gcc`, `g++`, `nasm`, `pkg-config`, `checkinstall`, `dkms`, `code` (.deb), `openjdk-17-jdk-headless`, `python-is-python3`, `pipx`, `docker-ce` + `containerd.io`, `mongodb-mongosh`, `pgadmin4-desktop`, `xvfb`, `adb`
- Hardver i sistem: `broadcom-sta-dkms`, `mbpfan`, `lm-sensors`, `powertop`, `intel-gpu-tools`, `vainfo`, `mesa-utils`, `efibootmgr`, `gparted`, `kyocera-sane`, `stress`, `systemd-zram-generator`, `zenity`
- Aplikacije: `google-chrome-stable`, `brave-browser`, `vlc`, `transmission`, `copyq`, `imagemagick`, `simple-scan`, `htop`, `autojump`, `screen`, `curl`
- Ostalo: `ibus-table-cangjie*`, `xfonts-cyrillic`, `xfonts-scalable`, `wbritish`

**Snap:** ručno `cheese`, `remmina`, `solvespace` (ostaju namerno); ostalo uz sistem. Flatpak nije instaliran.

**Van paketnih menadžera:** `/usr/local/bin` (`go`, `kubectl`, `helm`, `nosqlbooster4mongo`, `frontProxy`, `lowjson`; uz njih `go.new`, `helm3.15.2`, `kubectl1.30`), `~/.local/bin` (`claude`), `~/go/bin` (`gopls`, `golangci-lint`, `staticcheck`), npm globalno (`typescript`, `ts-node`), `~/.nvm`, `~/Android/Sdk`. Python je samo sistemski `python3.14`.

**apt repozitorijumi** (`resolute`): `ubuntu.sources`, `ubuntu-esm-apps`, `ubuntu-esm-infra`, `google-chrome`, `vscode`, `docker.sources`, `pgadmin4.sources`, `brave-browser-release.sources` (Brave, instaliran 2026-10-13; ključ `/usr/share/keyrings/brave-browser-archive-keyring.gpg`; vraćanje: `sudo apt remove brave-browser brave-keyring && sudo rm /etc/apt/sources.list.d/brave-browser-release.sources /usr/share/keyrings/brave-browser-archive-keyring.gpg`).

Ponavljanje popisa: `apt-mark showmanual; snap list; apt list --installed 2>/dev/null | grep ',local\]'; ls /usr/local/bin /opt ~/.local/bin ~/go/bin`.

### Uklonjeno 2026-10-10 (kako se vraća)

- **Noble ostaci:** stari headers/tools paketi, `postgresql-16`, `python3.11`/`3.12`, 87 `rc` paketa, rezervni kernel `6.8.0-146`. Jedini kernel je `7.0.0-38`; ako se ne podigne, live USB ili stariji kernel iz repozitorijuma.
- `xrdp`, `xfce4`, `xfce4-goodies`: `sudo apt install xrdp xfce4`. Virtuelizacija (`libvirt-*`, `qemu-system-x86`, `bridge-utils`, `dnsmasq`, `cpu-checker`): `sudo apt install libvirt-daemon-system qemu-system-x86`. Steam i 32-bitne biblioteke: `sudo dpkg --add-architecture i386 && sudo apt update`. `mainline`, `woeusb` i PPA-ovi (cappelikan, tomtomtom, deadsnakes).
- **`minikube`** sa `~/.minikube` (4,6 GB): nepovratno; posle ponovne instalacije `minikube start --driver=docker`.
- Snapovi `kf5-5-111-qt-5-15-11-core22`, `core18`, `canonical-livepatch` (nije bio uključen), 14 starih revizija; keš `apt`; journal na 200 MB.
- **Servisi ugašeni:** `ModemManager`, `cups-browsed`, `avahi-daemon` (+ socket); vraćanje `sudo systemctl enable --now avahi-daemon.socket avahi-daemon cups-browsed`. Štampač ECOSYS-M2135dn je statički (`socket://192.168.100.33`). `cups` i `bolt` ostaju.
- **`containerd`** ugašen (`systemctl disable --now containerd`; vraćanje `enable --now`), ali `docker.socket` ostaje uključen pa prvi `docker` poziv ponovo pokrene `docker.service` i `containerd`. Ako se `containerd` ugasi dok `docker` radi, dockerd je pokvaren: `sudo systemctl stop docker docker.socket`.
- **DNS:** posle uklanjanja `dnsmasq` `/etc/resolv.conf` je prebačen: `sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf`.
- **Lokalni PostgreSQL** uklonjen (pgAdmin se kači samo na udaljene baze `other` i `prod`): `apt purge postgresql-18 postgresql-client-18 postgresql-common postgresql-client-common`, klaster `main` i korisnik `postgres` obrisani. Ostali `pgadmin4-desktop`, `pgadmin4-server`, `libpq5`. Backup/Restore i psql u pgAdmin-u ne rade bez `postgresql-client-18` (pa Preferences → Paths → Binary paths `/usr/lib/postgresql/18/bin`). Vraćanje servera: `sudo apt install postgresql` (baza prazna).
- **`phoronix-test-suite`** (2026-10-11) sa `~/.phoronix-test-suite` (51 MB, uključujući sačuvan rezultat `test-results/qq`): rezultat je nepovratan; paket `sudo apt install phoronix-test-suite`.
- **`mkdocs`** (2026-10-14) sa 32 automatski povučena paketa (`python3-numpy`, `python3-nltk`, `python3-tqdm`, `python3-pytest`, `python3-dateutil`, `python3-tornado`, `libblas3`/`liblapack3` i dr.; 77,5 MB) i siročetom `/usr/local/bin/tqdm` (stara pip skripta 4.66.6, nepovratno, nije bila potrebna); vraćanje `sudo apt install mkdocs`.
- **Slanje crash izveštaja Canonical-u** (2026-10-14): `whoopsie.service`, `whoopsie.path` i `apport-autoreport.path` isključeni, zastavica `/var/lib/apport/autoreport` obrisana, `/var/crash` ispražnjen (50 MB, nepovratno). Razlog: `apport-autoreport` je padao zbog 504/400 od servera, a dump sadrži memoriju procesa (Chrome, VS Code, `copyq`, `seahorse`). Lokalni `apport` ostaje uključen. Vraćanje: `sudo systemctl enable --now whoopsie.path apport-autoreport.path && sudo touch /var/lib/apport/autoreport`.
- **Popravljeni servisi** (2026-10-14): `logrotate` (obrisan zastareli duplikat `/etc/logrotate.d/cloud-init`, isti sadržaj kao `cloud-init-base`; vraća ga `sudo apt install --reinstall cloud-init`, ali bi ponovo pravio grešku) i `snap.remmina.ssh-agent` (obrisan stari `ssh-agent.socket` u `/var/snap/remmina/7392/` ostao posle neurednog gašenja; ako se ponovi isto: obrisati taj fajl i `systemctl restart snap.remmina.ssh-agent`).
- **`isight-firmware-tools`** (2026-10-14): pravilo `80_isight.rules` je pokvareno (`${prefix}`), za USB iSight `05ac:8300`, a kamera je FaceTime HD (`14e4:1570`) i radi drugim putem; firmver `isight.fw` ne postoji. Vraćanje: `sudo apt install isight-firmware-tools`.

### Čišćenje home foldera (2026-10-10)

Oslobođeno ~19 GB (68 → 49 GB): keševi (`~/.cache/{pip,go-build,ms-playwright,puppeteer,torch}`, go modcache, `~/.npm/_cacache`, `~/.gradle/caches`; sami se vraćaju), `~/.pyenv` (Python 3.12.6; tri pyenv linije iz `.bashrc`), `~/.local/lib/python3.12` (`pip install --user ezdxf fonttools`), `~/.local/share/pipx`, `~/Documents/nanovna-saver` (kod sa upstream repoa NanoVNASaver).
