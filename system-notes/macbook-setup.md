# MacBook Pro 11,3 – sistemske izmene

**Hardver:** MacBook Pro 15" Retina (mid 2014), MacBookPro11,3, i7-4870HQ, Intel Iris Pro 5200 + NVIDIA GeForce GT 750M
**Sistem:** Ubuntu 26.04, kernel 7.0, GNOME Wayland. **Boot:** rEFInd → GRUB (`/EFI/ubuntu/grubx64.efi`); parametri kernela u `/etc/default/grub` i `/etc/default/grub.d/`.

## Kritično (ne diraj)

- **NVIDIA/grafika: vidi odeljak „NVIDIA i grafika: dva režima“ ispod.** Režim (A: Intel vozi ekran, NVIDIA ugašena; B: NVIDIA vozi ekran, HDMI radi) bira se samo skriptom `nv-nvidia on|off` i restartom; trenutni se vidi sa `nv-nvidia status`. `nvidia-off.service` sme biti uključen samo u režimu A. Zvanični drajver ne dolazi u obzir: serija 470 (poslednja za GT 750M) ne podržava kernel 7.0. Ako se vraća blokada nouveau-a, prvo ugasiti `nvidia-off.service`.
- **`/sys/power/disk` mora ostati `platform`** (podrazumevano). U režimu `shutdown` se hibernacija zaledi pri povratku (prisilno gašenje 10 s); uzrok nije utvrđen.
- **`/swap.img` pravi samo `nv-hibernate on|off`.** Pri svakom novom pravljenju fajla menja se `resume_offset`, a skripta ga sama upisuje na sva mesta (vidi hibernaciju niže).
- **`/etc/mbpfan.conf`:** ne vraćati stare test vrednosti (ventilatori na maksimumu). `mbpfan` i `thermald` ostaju; `macfanctld` ne instalirati uz `mbpfan`.
- **Ne koristiti `powertop --auto-tune` i ne instalirati TLP** (sudara se sa power-profiles-daemon; na bateriji profil **Power Saver**). U PowerTOP-u „Bad” ostaju namerno: autosuspend za Apple tastaturu/trackpad, runtime PM za NVIDIA i SATA link power management (Apple AHCI ne podržava ALPM).
- **Wi-Fi `wl` (BCM4360, `14e4:43a0`) je izuzet iz runtime PM-a** u `powersave-tune.sh`.

## NVIDIA i grafika: dva režima (bira se skriptom `nv-nvidia`)

Režim se bira **skriptom, ne ovim notesom**: `nv-nvidia on` (B) ili `nv-nvidia off` (A), pa restart; `nv-nvidia status` pokazuje šta ekran koristi sada. Ovde je zapisano samo kako to radi i kako se prepoznaje.

Ključ je koja grafika vozi **interni ekran od samog paljenja**. To bira firmver preko NVRAM promenljive `gpu-power-prefs-fa4ce28d-b62f-4c99-9cc3-6815686e30f9` (`07 00 00 00 01 00 00 00` = Intel, `07 00 00 00 00 00 00 00` = NVIDIA; vrednosti iz alata `gpu-switch`, oba smera potvrđena na ovoj mašini 2026-10-13). Kernel to ne može da promeni u radu. **Promenljiva se ne može obrisati:** posle paljenja efivarfs je ne prikazuje, iako je firmver pamti, a odmah posle upisa postoji ali se ne čita (`Invalid argument`, 4 bajta) do restarta. Zato se oba režima biraju upisom vrednosti, a režim se proverava po tome šta ekran stvarno koristi.

| | **A: Intel vozi ekran** (`nv-nvidia off`) | **B: NVIDIA vozi ekran** (`nv-nvidia on`) |
|---|---|---|
| `gpu-power-prefs` | `01` (integrisana) | `00` (diskretna) |
| `nvidia-off.service` | enabled | **disabled** (obavezno) |
| `glxinfo -B` renderer | Mesa Intel Iris Pro P5200 | `NVE7` (nouveau); Intel samo sa `DRI_PRIME=1` |
| i915 u logu | normalno | `failed to retrieve link info, disabling eDP` (očekivano, nema izlaza) |
| NVIDIA `power_state` | `D3hot` | `D0` |
| HDMI/TB | ne radi | radi (vidi niže) |
| Temperatura | jezgra 58–61°C u mirovanju | ~53–62°C u mirovanju; potrošnja i toplota veći pri opterećenju |

**Skripta** (`~/Documents/ubuntu/bin/nv-nvidia`, opis u `~/Documents/ubuntu/CLAUDE.md`): oba režima upisuju promenljivu (`printf … | tee`, 8 bajtova: `07 00 00 00` + `01` za Intel ili `00` za NVIDIA + `00 00 00`). Redosled sa servisom je bitan: `on` prvo gasi `nvidia-off.service`, `off` ga uključuje tek posle upisa. Posle `on`/`off` sledi restart. Bez skripte: `sudo chattr -i <fajl>; sudo rm <fajl>` (ako se vidi), pa upis istim `printf | sudo tee`.

**Provera režima:** `nv-nvidia status`; ili `readlink -f /sys/class/drm/card*/device` (nouveau je `card1` u B, `card2` u A; i915 obrnuto) i `glxinfo -B | grep renderer`.

**Spoljni monitor u režimu B** (isprobano 2026-10-13, Samsung 2560x1440, HDMI direktno): priključiti kabl. Ako GNOME ne vidi monitor (konektor `disconnected`, u `dmesg`: `nouveau: DDC responded, but no EDID for HDMI-A-1`), ručno zatražiti detekciju: `echo detect | sudo tee /sys/class/drm/card1-HDMI-A-1/status` (`card1` proveriti kao gore). Posle toga se pojavi `HDMI-1` i GNOME ga postavi desno od internog ekrana.

**Zašto se NVIDIA ne pali u radu** (provereno 2026-10-11, u režimu A): `echo ON > /sys/kernel/debug/vgaswitcheroo/switch` posle `OFF` ne uspeva (`Unable to change power state from D3cold to D0, device inaccessible`, nouveau `Client resume failed -16`; BAR-ovi ostaju nula). PCI `remove` + `rescan` ne pomaže: nouveau teardown zaglavi (`tee` u stanju D, `rescan` čeka iza njega, potreban restart). Uživo prebacivanje GPU-a (`IGD`/`DIS` u `switch`) nije probano: i915 je pri paljenju u B odustao od eDP-a, a pod Waylandom bi sesija verovatno pala. Zato se menja samo paljenjem.

**Upozorenje:** `nvidia-off.service` u režimu B ne uključivati (skripta to poštuje). Piše `OFF` u vga_switcheroo dok NVIDIA vozi ekran; ishod nije proveren, a Intel tada nema izlaz za ekran. `nv-nvidia status` javlja grešku za tu kombinaciju.

## Grafika i hlađenje (režim A)

Cilj je hladan i tih sistem u mirovanju: NVIDIA ugašena i hardversko dekodiranje videa preko Intela.

- Blokada nouveau-a uklonjena (`/etc/modprobe.d/blacklist-nouveau.conf.bak`); `nvidia-off.service` (enabled) pri paljenju upisuje `OFF` u vga_switcheroo; EFI promenljiva `gpu-power-prefs-fa4ce28d-b62f-4c99-9cc3-6815686e30f9` = `01` (ekran na Intelu).
- `/etc/environment`: `LIBVA_DRIVER_NAME=i965`; `/etc/X11/xorg.conf` → `xorg.conf.nvidia-old`; iz GRUB-a uklonjen `nvidia.drm-modeset=1`; uklonjen `vdpau-va-driver`.
- **Očekivano stanje:** jezgra u mirovanju 58–61°C, ventilatori ~2300 RPM; `glxinfo -B | grep renderer` → `Mesa Intel(R) Iris(R) Pro Graphics P5200`; `/sys/bus/pci/devices/0000:01:00.0/power_state` → `D3hot`; `sudo cat /sys/kernel/debug/vgaswitcheroo/switch` → `DIS ... Off`.
- **HDMI/TB idu preko NVIDIA-e** (vidi „NVIDIA i grafika: dva režima“): rade samo u režimu B.
- **Korisno:** `sensors`, `sudo intel_gpu_top`. YouTube: dodatak **enhanced-h264ify** (blokirati VP8/VP9/AV1), jer Haswell hardverski dekodira samo H.264.
- **Vraćanje** (posle grafičkih izmena restart):

```bash
sudo systemctl disable --now nvidia-off.service && sudo rm /etc/systemd/system/nvidia-off.service && sudo systemctl daemon-reload
sudo mv /etc/modprobe.d/blacklist-nouveau.conf.bak /etc/modprobe.d/blacklist-nouveau.conf && sudo update-initramfs -u
# gpu-power-prefs se ne može obrisati iz Linuxa: nv-nvidia on (NVIDIA, kao podrazumevano) ili NVRAM reset Cmd+Option+P+R
sudo mv /etc/X11/xorg.conf.nvidia-old /etc/X11/xorg.conf
# /etc/environment: staro LIBVA_DRIVER_NAME=nvidia (bez reda = automatski); GRUB: vratiti nvidia.drm-modeset=1 pa sudo update-grub
sudo apt install vdpau-va-driver
```

Ne može da se vrati: prateći xorg fajlovi.

## Indekser pretrage (`localsearch`)

- Ignorisani `go`, `snap`, `node_modules`, `vendor`, `venv`, `.venv`, `__pycache__`, `build`, `dist`, `target` (127 → ~6 hiljada fajlova); `~/Documents/videobolt` isključen fajlom `.trackerignore` (isto radi `touch <folder>/.trackerignore`).
- **Vraćanje:** `gsettings reset org.freedesktop.Tracker3.Miner.Files ignored-directories && localsearch reset --filesystem; rm ~/Documents/videobolt/.trackerignore`.

## Docker na zahtev

- `docker.service` i `containerd` se ne pale sa sistemom (`systemctl disable --now containerd`); `docker.socket` ostaje uključen, pa prvi `docker` poziv pokrene `docker.service` i `containerd`.
- Ako se `containerd` ugasi dok `docker` radi, dockerd je pokvaren: `sudo systemctl stop docker docker.socket`.
- **Vraćanje:** `sudo systemctl enable docker.service containerd`.
- Ne može da se vrati: obrisani Docker kontejneri (image `antenator-nec2-server` je ostao).

## Isključeni servisi

- `gpu-manager.service` maskiran: čekao je 10 s na NVIDIA udev pravila koja nikad ne stižu, a `gdm.service` ima `After=gpu-manager.service` (boot 23,6 → 14,2 s, vidi `analysis.md`). **Vraćanje:** `sudo systemctl unmask gpu-manager.service`.
- `ModemManager`, `cups-browsed`, `avahi-daemon` (+ socket) ugašeni. Štampač ECOSYS-M2135dn je statički (`socket://192.168.100.33`); `cups` i `bolt` ostaju. **Vraćanje:** `sudo systemctl enable --now avahi-daemon.socket avahi-daemon cups-browsed ModemManager`.
- **Slanje crash izveštaja Canonical-u:** `whoopsie.service`, `whoopsie.path` i `apport-autoreport.path` isključeni, zastavica `/var/lib/apport/autoreport` obrisana, `/var/crash` ispražnjen (nepovratno). Razlog: `apport-autoreport` je padao zbog 504/400 od servera, a dump sadrži memoriju procesa (Chrome, VS Code, `copyq`, `seahorse`). Lokalni `apport` ostaje uključen. **Vraćanje:** `sudo systemctl enable --now whoopsie.path apport-autoreport.path && sudo touch /var/lib/apport/autoreport`.

## Potrošnja i ventilatori

- **`powersave-tune.service`** (enabled, oneshot pri paljenju, `/usr/local/sbin/powersave-tune.sh`): NMI watchdog 0, `dirty_writeback_centisecs` 1500, runtime PM `auto` za PCI uređaje osim NVIDIA i Wi-Fi, za ATA port i `sda`/`sdb`, USB autosuspend samo za čitač kartica (05ac:8406). Backup: `powersave-tune.sh.bak-2026-10-10`. Ako posle sleep-a Wi-Fi ili SSD zabadaju, izuzeti ih u skripti. **Vraćanje:** `sudo systemctl disable --now powersave-tune.service && sudo rm /etc/systemd/system/powersave-tune.service /usr/local/sbin/powersave-tune.sh && sudo systemctl daemon-reload`.
- **`/etc/mbpfan.conf`:** `min_fan1_speed=2200`, `min_fan2_speed=2100`, `low_temp=55`, `high_temp=60`, `max_temp=70`, `polling_interval=1` (sa 58/64/80 ventilatori su kasno ubrzavali). **Ne raditi:** 50/55/60 je preglasno, jer su jezgra u mirovanju na 54–61 °C (2026-10-14, kernel 7.0); test vrednosti 10/20/30 °C drže ventilatore na ~6000 RPM. **Vraćanje:** vrednosti 58/64/80 su u `/etc/mbpfan.conf.bak-2026-10-14` (`sudo cp` preko `/etc/mbpfan.conf`, pa `sudo systemctl restart mbpfan`); na paketne: `sudo apt install --reinstall -o Dpkg::Options::=--force-confnew mbpfan`.
- **Wi-Fi:** kartica je izuzeta iz runtime PM-a u `powersave-tune.sh` (sa `auto` je `wl` ~10 min posle boota padao: `DISCONNECTED`, `SCAN-FAILED`). Poruke `wl_cfg80211_get_tx_power` su bezopasne. Ako opet padne, uzrok je sam `wl` na kernelu 7.0 (stariji kernel ili ethernet). Odmah: `echo auto | sudo tee /sys/bus/pci/devices/0000:03:00.0/power/control`.

## Hibernacija i suspend

- `/swap.img` = 20 GB. `/etc/default/grub.d/90-resume.cfg` (`resume=UUID=<root> resume_offset=<offset>`) i `/etc/initramfs-tools/conf.d/resume` (`RESUME=UUID=<root> resume_offset=<offset>`) pišu se skriptom; upozorenje `RESUME ... no matching swap device` je očekivano. Trenutni offset: `grep resume_offset /etc/default/grub.d/90-resume.cfg`.
- **Upravljanje: `nv-hibernate on|off`** (`~/Documents/ubuntu/bin/`, opis u `~/Documents/ubuntu/CLAUDE.md`). `off`: swap 4 GB, briše resume konfiguraciju, gasi ekstenziju; `on`: swap 20 GB, novi offset na sva mesta i u `/sys/power/resume_offset` (bez toga `CanHibernate=na` do restarta), pali ekstenziju. Posle `on` na komandnoj liniji se vidi novi offset tek posle restarta.
- Komandna linija je `quiet splash resume=… resume_offset=…`. Za debug (poruke pri paljenju i upisu slike, Ctrl+Alt+F3) privremeno bez restarta: `echo N | sudo tee /sys/module/printk/parameters/console_suspend` i `echo 7 | sudo tee /proc/sys/kernel/printk`.
- Polkit: Ubuntu zabranjuje hibernaciju, pa `/etc/polkit-1/rules.d/10-allow-hibernate.rules` dozvoljava grupi `sudo`. **Slabi polkit politiku:** hibernacija je dozvoljena svakom članu grupe `sudo`, iako je Ubuntu podrazumevano brani. Dugme u meniju: ekstenzija `hibernate-menu@local` (`extensions.md`).
- `/etc/UPower/UPower.conf.d/90-hibernate.conf`: `CriticalPowerAction=Hibernate` (pri 2 % baterije); promena pa `sudo systemctl restart upower`.
- Upis i čitanje slike traju ~10 s.
- **Vraćanje:** `nv-hibernate off` (swap 4 GB, briše `90-resume.cfg` i `conf.d/resume`, gasi ekstenziju); ručno: obrisati ta dva fajla, pa `sudo update-initramfs -u -k all && sudo update-grub`. Polkit i UPower: `sudo rm /etc/polkit-1/rules.d/10-allow-hibernate.rules /etc/UPower/UPower.conf.d/90-hibernate.conf && sudo systemctl restart upower`.

## Zram swap

- Paket `systemd-zram-generator`, konfiguracija `/etc/systemd/zram-generator.conf`: `[zram0]`, `zram-size = ram / 4` (4 GiB), `compression-algorithm = zstd`, `swap-priority = 100`. Kernel puni zram pre `/swap.img` (prioritet -1); hibernacija i dalje ide u `/swap.img` preko `resume=`.
- Zašto: swap se bez zrama praktično nije koristio (sysstat: najviše 1,8 MB, 0 OOM), pa je ovo mera predostrožnosti za teža opterećenja (VM-ovi, veliki buildovi). Zram je običan RAM, pa ulazi u hibernacionu sliku i vraća se pri buđenju.
- Provera: `swapon --show` (`/dev/zram0` prio 100 + `/swap.img` prio -1), `zramctl`.
- **Vraćanje:** `sudo systemctl stop systemd-zram-setup@zram0.service && sudo apt remove systemd-zram-generator && sudo rm /etc/systemd/zram-generator.conf`.

## Kamera (FaceTime HD, `14e4:1570`)

- Nezvanični `patjak/facetimehd` u `/usr/src/facetimehd-0.7.0.1` preko DKMS-a (gradi se sam za svaki kernel); firmver `/lib/firmware/facetimehd/firmware.bin`; nema Secure Boot-a. Provera: `dkms status`, `ls /dev/video0`, `cheese`.
- Kalibracioni fajl `/lib/firmware/facetimehd/1871_01XX.dat` (19040 B, MD5 `017996a51c95c6e11bc62683ad1f356b`); bez njega su boje blago pogrešne. Kopija je u repou: `system-notes/files/facetimehd/1871_01XX.dat` (nova instalacija: `sudo install -m 644` u `/lib/firmware/facetimehd/`).
- Izvlačenje fajla (ako kopija nestane): Apple Boot Camp 5.1.5769 (`download.info.apple.com/Mac_OS_X/031-30890-20150812-ea191174-4130-11e5-a125-930911ba098f/bootcamp5.1.5769.zip` → `BootCamp/Drivers/Apple/AppleCamera64.exe` je RAR, u njemu `AppleCamera.sys`; `dd bs=1 skip=1606800 count=19040`). RAR je solid pa ga libarchive ne čita; koristiti `unrar-cffi` u venv-u.
- Ako gradnja pukne: `cd /usr/src/facetimehd-0.7.0.1 && sudo git pull` (ili ponovo klonirati `https://github.com/patjak/facetimehd.git`), pa `sudo dkms install -m facetimehd -v 0.7.0.1`. Izvor firmvera: `git clone https://github.com/patjak/facetimehd-firmware.git`, `make && sudo make install`.
- **Vraćanje kalibracije:** `sudo rm /lib/firmware/facetimehd/1871_01XX.dat`. **Uklanjanje drajvera:** `sudo dkms remove -m facetimehd -v 0.7.0.1 --all && sudo rm -rf /usr/src/facetimehd-0.7.0.1 && sudo modprobe -r facetimehd`.

## Zatvaranje ekrana i idle na performance profilu

- **`/etc/systemd/logind.conf`:** `HandleLidSwitch=suspend`, `HandleLidSwitchExternalPower=lock` (laptop u torbi spava, uz punjač/monitor ostaje budan). Primena: `sudo systemctl kill -s HUP systemd-logind`. **Vraćanje:** backup `logind.conf.bak-2026-10-10` vratiti preko `logind.conf`, pa isti HUP.
- **Na performance profilu zatvaranje ekrana ne radi ništa:** `lid-ignore-performance.service` (enabled, `/etc/systemd/system/`, skripta `/usr/local/sbin/lid-ignore-performance`) sluša D-Bus `net.hadess.PowerProfiles` (`ActiveProfile`) i dok je profil performance drži `systemd-inhibit --what=handle-lid-switch` (logind tada ne radi ni suspend ni lock); na ostalim profilima inhibitor se pušta pa važi `logind.conf`. **Vraćanje:** `sudo systemctl disable --now lid-ignore-performance.service && sudo rm /etc/systemd/system/lid-ignore-performance.service /usr/local/sbin/lid-ignore-performance && sudo systemctl daemon-reload`.
- **Na performance profilu nema idle-a** (zamena za caffeine): user usluga `~/.config/systemd/user/performance-no-idle.service` (enabled, skripta `~/.local/bin/performance-no-idle`) sluša isti D-Bus i dok je profil performance drži `gnome-session-inhibit --inhibit idle` (nema gašenja ekrana ni idle suspenda). **Vraćanje:** `systemctl --user disable --now performance-no-idle.service && rm ~/.config/systemd/user/performance-no-idle.service ~/.local/bin/performance-no-idle`.

## Bluetooth ugašen po defaultu

- `/etc/bluetooth/main.conf` `[Policy] AutoEnable=false`. **Vraćanje:** backup `main.conf.bak-2026-10-10` vratiti preko `main.conf`, pa `sudo systemctl restart bluetooth`.
- Izlazak iz airplane moda ga ipak pali, pa `bt-airplane-guard.service` (enabled, `/usr/local/sbin/bt-airplane-guard.sh`) sluša `rfkill event` i blokira ga ako se Wi-Fi i Bluetooth odblokiraju u razmaku do 3 s (ručno paljenje oba u 3 s ga ostavi ugašenog). **Vraćanje:** `sudo systemctl disable --now bt-airplane-guard.service && sudo rm /etc/systemd/system/bt-airplane-guard.service /usr/local/sbin/bt-airplane-guard.sh && sudo systemctl daemon-reload`.

## Turbo i CPU frekvencija po power profilu

`turbo-follow-profile.service` (enabled, `/etc/systemd/system/`, skripta `/usr/local/sbin/turbo-follow-profile`, rezervna kopija starije skripte `turbo-follow-profile.bak`) sluša D-Bus `net.hadess.PowerProfiles` (`ActiveProfile`) i pri promeni profila i pri startu upisuje:

- **`no_turbo`:** `0` (turbo uključen) samo za performance, `1` za ostale.
- **`scaling_max_freq` svih jezgara:** na power-saver limit iz `/var/lib/turbo-follow-profile/saver-max-khz` (kHz, default 1600000; skripta ga ograničava na opseg CPU-a; menja ga klizač ekstenzije `powersaver-freq@local`, `extensions.md`); na ostalim profilima `cpuinfo_max_freq`, čitan uživo posle upisa `no_turbo` (3.7 GHz sa turbom, 2.5 GHz bez njega).
- **Idle cap:** ekstenzija `powersaver-freq@local` upisuje u `/var/lib/turbo-follow-profile/idle` nivo `0` (aktivan), `1` (15 s bez miša/tastature) ili `2` (30 s). Power-saver pri nivou ≥1: `cpuinfo_min_freq` (800 MHz) umesto klizača. Balanced pri nivou 2: `BALANCED_IDLE_KHZ` = 1 GHz (u skripti). Na punjaču (`/sys/class/power_supply/ADP1/online` = 1) balanced se ne spušta, a power-saver se spušta.
- **Brzina reakcije:** na power-saver i balanced servis proverava fajlove (`saver-max-khz`, `idle`, punjač) na svakih 0,3 s, na performance na 2 s; trenutni profil čuva u `/run/turbo-follow-profile.profile`.
- **PPD:** čita `no_turbo` samo pri startu (sysfs ne šalje inotify), pa bi posle paljenja turba javljao `Degraded: high-operating-temperature`; zato servis, ako je oznaka postavljena, restartuje `power-profiles-daemon.service` (najviše jednom u 10 s). PPD sam ovde ništa ne menja (nema EPP-a ni platform profila, `intel_pstate` je passive). Svetlinu ekrana servis ne dira (to radi ekstenzija).
- **Ručno:** `echo 0|1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo` (važi do sledeće promene profila).
- **Vraćanje samo idle capa:** u ekstenziji ukloniti idle watch, a u skripti `IDLE_FILE`/`saver_cap`.
- **Vraćanje:** `sudo systemctl disable --now turbo-follow-profile.service && sudo rm -r /etc/systemd/system/turbo-follow-profile.service /usr/local/sbin/turbo-follow-profile /var/lib/turbo-follow-profile && sudo systemctl daemon-reload`, pa vratiti `scaling_max_freq` na 2500000 (ili restart). Za turbo ugašen na bootu bez praćenja profila: oneshot servis koji upisuje `1` u `no_turbo`.

## Shell i terminal

- Aliasi su u `~/.bash_aliases` (učitava ga `~/.bashrc`), ne u samom `~/.bashrc`. **Vraćanje:** prebaciti sadržaj nazad u `~/.bashrc` i obrisati `~/.bash_aliases`.
- **GNOME Terminal, F10 slobodan za aplikacije (htop `F10` = Quit):** `gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false`. **Vraćanje:** isto sa `true`.

## Podrazumevani pregledač (Firefox)

- `xdg-settings set default-web-browser firefox_firefox.desktop` (upisano u `~/.config/mimeapps.list`: `http`, `https`, `html`); alternative `x-www-browser` i `gnome-www-browser` ručno pinovane na `/usr/bin/firefox` (inače `x-www-browser` bira pregledač po prioritetu, a ne Firefox).
- Ako snap Firefox ne koristi VA-API (`intel_gpu_top`: Video na 0% dok ide video), instalirati Firefox iz Mozillinog APT repozitorijuma.
- Za tešku browser igru: `google-chrome-stable` (`.deb`, repo `/etc/apt/sources.list.d/google-chrome.sources`) uz power profil koji gasi turbo (Balanced/Power Saver).
- **Vraćanje:** `sudo update-alternatives --auto x-www-browser && sudo update-alternatives --auto gnome-www-browser`. Chrome: `sudo apt remove google-chrome-stable && sudo rm /etc/apt/sources.list.d/google-chrome.sources`.

## NoSQLBooster (ručna instalacija)

- `/usr/local/nosqlbooster4mongo` (ručno raspakovan tarball, symlink `/usr/local/bin/nosqlbooster4mongo`; nije u apt-u/snap-u, ažurira se ručno), verzija 11.2.0 sa `https://s3.nosqlbooster.com/download/releasesv11/nosqlbooster4mongo-11.2.0-x64.tar.gz`. Podešavanja su van instalacije (`~/.config/NoSQLBooster for MongoDB`, `~/Documents/NoSQLBooster`).
- Ažuriranje: ugasiti aplikaciju, raspakovati sa `--strip-components=1`, `chown -R monrasta:monrasta`, `chrome-sandbox` `root:root` i `chmod 4755`.
- **Uklanjanje:** `sudo rm -rf /usr/local/nosqlbooster4mongo /usr/local/bin/nosqlbooster4mongo` (podešavanja ostaju).

## Uklonjeno

Jedan red po uklonjenoj stvari: šta, kada i kako se vraća.

- **Noble ostaci** (2026-10-10): stari headers/tools paketi, `postgresql-16`, `python3.11`/`3.12`, 87 `rc` paketa, rezervni kernel `6.8.0-146`. Jedini kernel je `7.0.0-38`; ako se ne podigne, live USB ili stariji kernel iz repozitorijuma.
- **`xrdp`, `xfce4`, `xfce4-goodies`** (2026-10-10): `sudo apt install xrdp xfce4`.
- **Virtuelizacija** (`libvirt-*`, `qemu-system-x86`, `bridge-utils`, `dnsmasq`, `cpu-checker`; 2026-10-10): `sudo apt install libvirt-daemon-system qemu-system-x86`. Posle uklanjanja `dnsmasq` `/etc/resolv.conf` pokazuje na `/run/systemd/resolve/stub-resolv.conf` (Ubuntu podrazumevano; prethodna meta nije zabeležena).
- **Steam i 32-bitne biblioteke** (2026-10-10): `sudo dpkg --add-architecture i386 && sudo apt update`, pa Steam.
- **`mainline`, `woeusb` i PPA-ovi** cappelikan, tomtomtom, deadsnakes (2026-10-10): ponovo dodati PPA i instalirati.
- **`minikube`** sa `~/.minikube` (4,6 GB; 2026-10-10): podaci nepovratni; posle ponovne instalacije `minikube start --driver=docker`.
- **Snapovi** `kf5-5-111-qt-5-15-11-core22`, `core18`, `canonical-livepatch` (nije bio uključen) i 14 starih revizija; keš `apt`; journal jednom očišćen na 200 MB, bez trajnog limita (`SystemMaxUse` u `journald.conf` nije postavljen) (2026-10-10): `sudo snap install <ime>`.
- **`macfanctld`** (`apt purge`): radio je uporedo sa `mbpfan`, oba su upravljala ventilatorima. Ne vraćati (vidi „Kritično“).
- **Lokalni PostgreSQL** (`postgresql-18`, `postgresql-client-18`, `postgresql-common`, `postgresql-client-common`; klaster `main` i korisnik `postgres` obrisani): pgAdmin se kači samo na udaljene baze `other` i `prod`; ostali `pgadmin4-desktop`, `pgadmin4-server`, `libpq5`. Backup/Restore i psql u pgAdmin-u ne rade bez `postgresql-client-18` (pa Preferences → Paths → Binary paths `/usr/lib/postgresql/18/bin`). Vraćanje servera: `sudo apt install postgresql` (baza prazna).
- **`phoronix-test-suite`** sa `~/.phoronix-test-suite` (2026-10-11): rezultat `test-results/qq` nepovratan; `sudo apt install phoronix-test-suite`.
- **`mkdocs`** sa 32 automatski povučena paketa i siročetom `/usr/local/bin/tqdm` (stara pip skripta, nepovratno; 2026-10-14): `sudo apt install mkdocs`.
- **`isight-firmware-tools`** (2026-10-14): pravilo `80_isight.rules` je bilo pokvareno i za USB iSight `05ac:8300`, a kamera je FaceTime HD: `sudo apt install isight-firmware-tools`.
- **`/etc/logrotate.d/cloud-init`** (2026-10-14): zastareli duplikat `cloud-init-base` koji je rušio `logrotate`. Vraća ga `sudo apt install --reinstall cloud-init`, ali bi ponovo pravio grešku.
- **Stari `ssh-agent.socket` u `/var/snap/remmina/7392/`** (2026-10-14): ostao posle neurednog gašenja i rušio `snap.remmina.ssh-agent`. Ako se ponovi: obrisati fajl i `systemctl restart snap.remmina.ssh-agent`.
- **Brave** (paketi, repozitorijum, ključevi, profil): ponovo instalirati po uputstvu sa brave.com.
- **caffeine:** zamenjen uslugom `performance-no-idle` (vidi „Zatvaranje ekrana i idle na performance profilu“).
- **`turbo-off-boot.service`:** zamenjen servisom `turbo-follow-profile` (vidi „Turbo i CPU frekvencija po power profilu“).
- **Čišćenje home foldera** (2026-10-10, ~19 GB): keševi (`~/.cache/{pip,go-build,ms-playwright,puppeteer,torch}`, go modcache, `~/.npm/_cacache`, `~/.gradle/caches`; sami se vraćaju), `~/.pyenv` (Python 3.12.6; tri pyenv linije iz `.bashrc`), `~/.local/lib/python3.12` (`pip install --user ezdxf fonttools`), `~/.local/share/pipx`, `~/Documents/nanovna-saver` (kod sa upstream repoa NanoVNASaver).
