# MacBook Pro 11,3 – sistemske izmene

**Hardver:** MacBook Pro 15" Retina (mid 2014), MacBookPro11,3, i7-4870HQ, Intel Iris Pro 5200 + NVIDIA GeForce GT 750M
**Sistem:** Ubuntu 26.04, kernel 7.0, GNOME Wayland. **Boot:** rEFInd → GRUB (`/EFI/ubuntu/grubx64.efi`); parametri kernela u `/etc/default/grub` i `/etc/default/grub.d/`.

## Kritično (ne diraj)

- **NVIDIA/grafika: vidi odeljak „NVIDIA i grafika: režimi i stanje“ ispod.** Sada radi režim **B (NVIDIA vozi ekran)**, a `nvidia-off.service` je isključen i **ne sme se uključiti** dok je firmver na NVIDIA-i. Zvanični drajver ne dolazi u obzir: serija 470 (poslednja za GT 750M) ne podržava kernel 7.0. Ako se vraća blokada nouveau-a, prvo ugasiti `nvidia-off.service`.
- **`/sys/power/disk` mora ostati `platform`** (podrazumevano). U režimu `shutdown` se hibernacija zaledi pri povratku (prisilno gašenje 10 s); uzrok nije utvrđen.
- **`/swap.img` pravi samo `nv-hibernate on|off`.** Pri svakom novom pravljenju fajla menja se `resume_offset`, a skripta ga sama upisuje na sva mesta (vidi hibernaciju niže).
- **`/etc/mbpfan.conf`:** ne vraćati stare test vrednosti (ventilatori na maksimumu). `mbpfan` i `thermald` ostaju; `macfanctld` ne instalirati uz `mbpfan`.
- **Ne koristiti `powertop --auto-tune` i ne instalirati TLP** (sudara se sa power-profiles-daemon; na bateriji profil **Power Saver**). U PowerTOP-u „Bad” ostaju namerno: autosuspend za Apple tastaturu/trackpad, runtime PM za NVIDIA i SATA link power management (Apple AHCI ne podržava ALPM).
- **Wi-Fi `wl` (BCM4360, `14e4:43a0`) je izuzet iz runtime PM-a** u `powersave-tune.sh`.

## NVIDIA i grafika: režimi i stanje (ažurirano 2026-10-13)

Ključ svega je koja grafika vozi **interni ekran od samog paljenja**. To bira firmver preko NVRAM promenljive `gpu-power-prefs-fa4ce28d-b62f-4c99-9cc3-6815686e30f9` (`07 00 00 00 01 00 00 00` = Intel; nema promenljive = NVIDIA). Kernel to ne može da promeni u radu.

| | **A: Intel vozi ekran** | **B: NVIDIA vozi ekran (SADA)** |
|---|---|---|
| `gpu-power-prefs` | postoji, `01` | ne postoji (obrisana, vidi niže) |
| `nvidia-off.service` | enabled | **disabled** (obavezno) |
| `glxinfo -B` renderer | Mesa Intel Iris Pro P5200 | `NVE7` (nouveau); Intel samo sa `DRI_PRIME=1` |
| i915 u logu | normalno | `failed to retrieve link info, disabling eDP` (očekivano, nema izlaza) |
| NVIDIA `power_state` | `D3hot` | `D0` |
| HDMI/TB | ne radi | radi (vidi niže) |
| Temperatura | jezgra 58–61°C u mirovanju | merena samo 53°C u mirovanju; potrošnja i toplota veći pri opterećenju |

**Zašto je sada B:** 2026-10-11 nismo uspeli da upalimo NVIDIA-u u radu za HDMI (vidi niže), pa je `nvidia-off.service` isključen i urađen restart. Do 2026-10-12 je promenljiva `gpu-power-prefs` obrisana, pa firmver od tada šalje ekran na NVIDIA-u. Korisnik je 2026-10-13 odlučio da ostane tako jer temperature nisu visoke.

**Provera režima:** `readlink -f /sys/class/drm/card*/device` (nouveau je `card1`, i915 `card2`); `glxinfo -B | grep renderer`; `ls /sys/firmware/efi/efivars | grep gpu-power`; `systemctl is-enabled nvidia-off.service`.

**Spoljni monitor u režimu B** (isprobano 2026-10-13, Samsung 2560x1440, HDMI direktno): priključiti kabl. Ako GNOME ne vidi monitor (konektor `disconnected`, u `dmesg`: `nouveau: DDC responded, but no EDID for HDMI-A-1`), ručno zatražiti detekciju: `echo detect | sudo tee /sys/class/drm/card1-HDMI-A-1/status` (`card1` proveriti kao gore). Posle toga se pojavi `HDMI-1` i GNOME ga postavi desno od internog ekrana.

**Zašto se NVIDIA ne pali u radu** (provereno 2026-10-11, u režimu A): `echo ON > /sys/kernel/debug/vgaswitcheroo/switch` posle `OFF` ne uspeva (`Unable to change power state from D3cold to D0, device inaccessible`, nouveau `Client resume failed -16`; BAR-ovi ostaju nula). PCI `remove` + `rescan` ne pomaže: nouveau teardown zaglavi (`tee` u stanju D, `rescan` čeka iza njega, potreban restart). Uživo prebacivanje GPU-a (`IGD`/`DIS` u `switch`) nije probano: i915 je pri paljenju u B odustao od eDP-a, a pod Waylandom bi sesija verovatno pala. Zato se menja samo paljenjem.

**Skripta:** `nv-nvidia on|off|status` radi oba prelaza ispod (`on` = B, `off` = A, `status` samo prikazuje stanje); posle `on`/`off` sledi restart. Ručni koraci su zapisani da se vidi šta skripta radi.

**Prelazak B → A (Intel, hladnije):**
1. Upisati promenljivu: `printf '\x07\x00\x00\x00\x01\x00\x00\x00' | sudo tee /sys/firmware/efi/efivars/gpu-power-prefs-fa4ce28d-b62f-4c99-9cc3-6815686e30f9 >/dev/null` (format viđen u ranijem `xxd`; upis nije ponovo proveren).
2. `sudo systemctl enable nvidia-off.service`.
3. Restart; proveriti kao u tabeli (kolona A).

**Prelazak A → B:** `sudo systemctl disable nvidia-off.service`, obrisati promenljivu (`sudo chattr -i <fajl>; sudo rm <fajl>`), restart.

**Upozorenje:** `nvidia-off.service` u režimu B ne uključivati. Piše `OFF` u vga_switcheroo, a NVIDIA tada vozi ekran; ishod nije proveren, a Intel nema izlaz za ekran.

## Grafika i hlađenje (2026-10-08, rešeno; opisuje režim A)

Procesor je posle paljenja išao na 90–100°C: NVIDIA je radila bez drajvera (CPU je renderovao softverski), indekser je skenirao 127 hiljada fajlova, a `LIBVA_DRIVER_NAME=nvidia` je kvario dekodiranje videa.

- Blokada nouveau-a uklonjena (`/etc/modprobe.d/blacklist-nouveau.conf.bak`); `nvidia-off.service` (enabled) pri paljenju upisuje `OFF` u vga_switcheroo; EFI promenljiva `gpu-power-prefs-fa4ce28d-b62f-4c99-9cc3-6815686e30f9` = `01` (ekran na Intelu).
- `/etc/environment`: `LIBVA_DRIVER_NAME=i965`; `/etc/X11/xorg.conf` → `xorg.conf.nvidia-old`; iz GRUB-a uklonjen `nvidia.drm-modeset=1`; uklonjen `vdpau-va-driver`.
- Indekser (`localsearch`): ignorisani `go`, `snap`, `node_modules`, `vendor`, `venv`, `.venv`, `__pycache__`, `build`, `dist`, `target` (127 → ~6 hiljada fajlova); `~/Documents/videobolt` isključen fajlom `.trackerignore` (isto radi `touch <folder>/.trackerignore`).
- Docker se ne pali sa sistemom (`docker.socket` ga pokreće na zahtev).
- `gpu-manager.service` maskiran: čekao je 10 s na NVIDIA udev pravila (vidi `analysis.md`, trajanje boota).
- **Očekivano stanje:** jezgra u mirovanju 58–61°C, ventilatori ~2300 RPM; `glxinfo -B | grep renderer` → `Mesa Intel(R) Iris(R) Pro Graphics P5200`; `/sys/bus/pci/devices/0000:01:00.0/power_state` → `D3hot`; `sudo cat /sys/kernel/debug/vgaswitcheroo/switch` → `DIS ... Off`.
- **HDMI/TB idu preko NVIDIA-e** (vidi „NVIDIA i grafika: režimi i stanje“: u režimu A radi samo posle restarta, u B odmah).
- **Korisno:** `nv-turbo on|off` (do restarta), `sensors`, `sudo intel_gpu_top`. YouTube: dodatak **enhanced-h264ify** (blokirati VP8/VP9/AV1), jer Haswell hardverski dekodira samo H.264.
- **Vraćanje** (posle grafičkih izmena restart):

```bash
sudo systemctl disable --now nvidia-off.service && sudo rm /etc/systemd/system/nvidia-off.service && sudo systemctl daemon-reload
sudo mv /etc/modprobe.d/blacklist-nouveau.conf.bak /etc/modprobe.d/blacklist-nouveau.conf && sudo update-initramfs -u
sudo chattr -i /sys/firmware/efi/efivars/gpu-power-prefs-fa4ce28d-*; sudo rm /sys/firmware/efi/efivars/gpu-power-prefs-fa4ce28d-*   # ili NVRAM reset Cmd+Option+P+R
sudo mv /etc/X11/xorg.conf.nvidia-old /etc/X11/xorg.conf
# /etc/environment: staro LIBVA_DRIVER_NAME=nvidia (bez reda = automatski); GRUB: vratiti nvidia.drm-modeset=1 pa sudo update-grub
sudo apt install vdpau-va-driver
gsettings reset org.freedesktop.Tracker3.Miner.Files ignored-directories && localsearch reset --filesystem; rm ~/Documents/videobolt/.trackerignore
sudo systemctl enable docker.service
sudo systemctl unmask gpu-manager.service
```

Ne može da se vrati: obrisani Docker kontejneri (image `antenator-nec2-server` je ostao) i prateći xorg fajlovi.

## Potrošnja i ventilatori (rešeno)

- **`powersave-tune.service`** (enabled, oneshot pri paljenju, `/usr/local/sbin/powersave-tune.sh`): NMI watchdog 0, `dirty_writeback_centisecs` 1500, runtime PM `auto` za PCI uređaje osim NVIDIA i Wi-Fi, za ATA port i `sda`/`sdb`, USB autosuspend samo za čitač kartica (05ac:8406). Backup: `powersave-tune.sh.bak-2026-10-10`. Ako posle sleep-a Wi-Fi ili SSD zabadaju, izuzeti ih u skripti. **Vraćanje:** `sudo systemctl disable --now powersave-tune.service && sudo rm /etc/systemd/system/powersave-tune.service /usr/local/sbin/powersave-tune.sh && sudo systemctl daemon-reload`.
- **`macfanctld`** uklonjen (`apt purge`): radio je uporedo sa `mbpfan`, oba su upravljala ventilatorima.
- **`/etc/mbpfan.conf`:** `min_fan1_speed=2200`, `min_fan2_speed=2100`, `low_temp=58`, `high_temp=64`, `max_temp=80`, `polling_interval=1` (ranije test vrednosti 10/20/30 °C držale su ventilatore na ~6000 RPM). Sada ~2200 RPM, CPU ~37°C. **Vraćanje na paketne vrednosti:** `sudo apt install --reinstall -o Dpkg::Options::=--force-confnew mbpfan`; backup sa test vrednostima je `/etc/mbpfan.conf.bak-2026-10-10`.
- **Wi-Fi:** `wl` je ~10 min posle boota padao (`DISCONNECTED`, `SCAN-FAILED`) jer je `powersave-tune` stavio runtime PM `auto` na karticu. Izuzeta; zatvoreno 2026-10-10. Poruke `wl_cfg80211_get_tx_power` su bezopasne. Ako opet padne, uzrok je sam `wl` na kernelu 7.0 (stariji kernel ili ethernet). Odmah: `echo auto | sudo tee /sys/bus/pci/devices/0000:03:00.0/power/control`.
- Ako snap Firefox ne koristi VA-API (`intel_gpu_top`: Video na 0% dok ide video), instalirati Firefox iz Mozillinog APT repozitorijuma. Za tešku browser igru: `google-chrome-stable` (`.deb`, repo `/etc/apt/sources.list.d/google-chrome.sources`) uz `nv-turbo off`; uklanjanje `sudo apt remove google-chrome-stable && sudo rm /etc/apt/sources.list.d/google-chrome.sources`.

## Hibernacija i suspend (rade, 2026-10-11)

- `/swap.img` = 20 GB. `/etc/default/grub.d/90-resume.cfg` (`resume=UUID=<root> resume_offset=<offset>`) i `/etc/initramfs-tools/conf.d/resume` (`RESUME=UUID=<root> resume_offset=<offset>`) pišu se skriptom; upozorenje `RESUME ... no matching swap device` je očekivano. Trenutni offset: `grep resume_offset /etc/default/grub.d/90-resume.cfg`.
- **Upravljanje: `nv-hibernate on|off`** (`~/Documents/ubuntu/bin/`, opis u `~/Documents/ubuntu/CLAUDE.md`). `off`: swap 4 GB, briše resume konfiguraciju, gasi ekstenziju; `on`: swap 20 GB, novi offset na sva mesta i u `/sys/power/resume_offset` (bez toga `CanHibernate=na` do restarta), pali ekstenziju. Posle `on` na komandnoj liniji se vidi novi offset tek posle restarta.
- Komandna linija je `quiet splash resume=… resume_offset=…`. Za debug (poruke pri paljenju i upisu slike, Ctrl+Alt+F3) privremeno bez restarta: `echo N | sudo tee /sys/module/printk/parameters/console_suspend` i `echo 7 | sudo tee /proc/sys/kernel/printk`.
- Polkit: Ubuntu zabranjuje hibernaciju, pa `/etc/polkit-1/rules.d/10-allow-hibernate.rules` dozvoljava grupi `sudo`. Dugme u meniju: ekstenzija `hibernate-menu@local` (`extensions.md`).
- `/etc/UPower/UPower.conf.d/90-hibernate.conf`: `CriticalPowerAction=Hibernate` (pri 2 % baterije); promena pa `sudo systemctl restart upower`.
- Istorija: prvi pokušaj nije učitao sliku (uzrok nepoznat), drugi radi (~10 s upis i čitanje). Fragmentacija swap fajla nije uzrok problema.
- **Vraćanje:** obrisati `90-resume.cfg` i `conf.d/resume`, pa `sudo update-initramfs -u -k all && sudo update-grub`; swap: `nv-hibernate off`.

## Zram swap (uključen, 2026-10-11)

- Paket `systemd-zram-generator`, konfiguracija `/etc/systemd/zram-generator.conf`: `[zram0]`, `zram-size = ram / 4` (4 GiB), `compression-algorithm = zstd`, `swap-priority = 100`. Kernel puni zram pre `/swap.img` (prioritet -1); hibernacija i dalje ide u `/swap.img` preko `resume=`.
- Zašto: pre toga se swap praktično nije koristio (sysstat od 8. 10: najviše 1,8 MB, 0 OOM), pa je ovo više mera predostrožnosti za teža opterećenja (VM-ovi, veliki buildovi) nego rešenje stvarnog problema. Zram je običan RAM, pa ulazi u hibernacionu sliku i vraća se pri buđenju.
- Provera: `swapon --show` (`/dev/zram0` prio 100 + `/swap.img` prio -1), `zramctl`.
- **Vraćanje:** `sudo systemctl stop systemd-zram-setup@zram0.service && sudo apt remove systemd-zram-generator && sudo rm /etc/systemd/zram-generator.conf`.

## Ostalo

- **Zatvaranje ekrana (`/etc/systemd/logind.conf`):** `HandleLidSwitch=suspend`, `HandleLidSwitchExternalPower=lock` (laptop u torbi spava, uz punjač/monitor ostaje budan). Primena: `sudo systemctl kill -s HUP systemd-logind`. Backup: `logind.conf.bak-2026-10-10`.
- **Bluetooth ugašen po defaultu:** `/etc/bluetooth/main.conf` `[Policy] AutoEnable=false` (backup `main.conf.bak-2026-10-10`, vraćanje + `sudo systemctl restart bluetooth`). Izlazak iz airplane moda ga ipak pali, pa `bt-airplane-guard.service` (enabled, `/usr/local/sbin/bt-airplane-guard.sh`) sluša `rfkill event` i blokira ga ako se Wi-Fi i Bluetooth odblokiraju u razmaku do 3 s (ručno paljenje oba u 3 s ga ostavi ugašenog). **Vraćanje:** `sudo systemctl disable --now bt-airplane-guard.service && sudo rm /etc/systemd/system/bt-airplane-guard.service /usr/local/sbin/bt-airplane-guard.sh && sudo systemctl daemon-reload`.
- **Kamera (FaceTime HD, `14e4:1570`):** nezvanični `patjak/facetimehd` u `/usr/src/facetimehd-0.7.0.1` preko DKMS-a (gradi se sam za svaki kernel); firmver `/lib/firmware/facetimehd/firmware.bin`; nema Secure Boot-a. Provera: `dkms status`, `ls /dev/video0`, `cheese`. Kalibracioni fajl `/lib/firmware/facetimehd/1871_01XX.dat` (19040 B, MD5 `017996a51c95c6e11bc62683ad1f356b`) je ručno izvučen iz Apple Boot Camp 5.1.5769 (`download.info.apple.com/Mac_OS_X/031-30890-20150812-ea191174-4130-11e5-a125-930911ba098f/bootcamp5.1.5769.zip` → `BootCamp/Drivers/Apple/AppleCamera64.exe` je RAR, u njemu `AppleCamera.sys`; `dd bs=1 skip=1606800 count=19040`); RAR je solid pa ga libarchive ne čita, korišćen je `unrar-cffi` u venv-u. Bez njega boje su blago pogrešne. Kopija fajla je u repou: `system-notes/files/facetimehd/1871_01XX.dat` (za novu instalaciju: `sudo install -m 644` u `/lib/firmware/facetimehd/`). Vraćanje: `sudo rm /lib/firmware/facetimehd/1871_01XX.dat`. Ako gradnja pukne: `cd /usr/src/facetimehd-0.7.0.1 && sudo git pull` (ili ponovo klonirati `https://github.com/patjak/facetimehd.git`), pa `sudo dkms install -m facetimehd -v 0.7.0.1`. Izvor firmvera (ako zatreba): `git clone https://github.com/patjak/facetimehd-firmware.git`, `make && sudo make install`. **Uklanjanje:** `sudo dkms remove -m facetimehd -v 0.7.0.1 --all && sudo rm -rf /usr/src/facetimehd-0.7.0.1 && sudo modprobe -r facetimehd`.
- **Turbo ugašen po defaultu:** `turbo-off-boot.service` (enabled, `/etc/systemd/system/`) pri bootu upisuje `1` u `/sys/devices/system/cpu/intel_pstate/no_turbo`; ručno paljenje do sledećeg restarta: `nv-turbo on` (`nv-turbo off` ga opet gasi). **Vraćanje:** `sudo systemctl disable --now turbo-off-boot.service && sudo rm /etc/systemd/system/turbo-off-boot.service && sudo systemctl daemon-reload`.
- **Aliasi** iz `~/.bashrc` prebačeni u `~/.bash_aliases` (turbo aliasi zamenjeni skriptom `nv-turbo`).
- **GNOME Terminal, F10 slobodan za aplikacije (htop `F10` = Quit):** `gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false`; vraćanje `... true`.
