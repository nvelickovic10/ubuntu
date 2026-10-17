# Analize

## Potrošnja baterije (merenja 2026-10-09/10)

Posle PowerTOP podešavanja i gašenja `macfanctld` (vidi [macbook-setup.md](macbook-setup.md)): pod opterećenjem 15,8–28 W (prosek ~21,6 W), u mirovanju sa uključenim ekranom ~13–14,5 W. Package C-stanja (PC6) nikad ne ulaze u duboko spavanje; to je najveći gubitak, ali dalja analiza (ASPM, Thunderbolt, xHCI) zatvorena je po odluci korisnika. Gašenje `gpe17` ne pomaže (`acpi_mask_gpe=0x17` nije potreban), a SATA ALPM Apple AHCI ne podržava. Provera posle punjenja (2026-10-10): baterija 107 Wh od 99,99 Wh, 142 ciklusa, bez problema.

Merenje: root petlja pravi PowerTOP CSV na 30 s: `sudo -b sh -c 'while true; do powertop --time=30 --csv=/tmp/powertop.tmp >/dev/null 2>&1 && chmod 644 /tmp/powertop.tmp && mv /tmp/powertop.tmp /tmp/powertop.csv; done'`; gašenje `sudo pkill -f 'while true; do powertop'; sudo pkill powertop`.

## Termalni test CPU-a po limitu frekvencije (2026-10-17)

Ista mašina (i7-4870HQ, MacBookPro11,3, kernel 7.0.0-38), test `stress --cpu $(nproc) --timeout 60` (8 radnika, samo CPU) uz uzorkovanje na 5 s: temperatura `x86_pkg_temp`, brojač `thermal_throttle/*_throttle_count`, takt, ventilator. Limit na performance profilu postavlja klizač „Performance max CPU“ (vidi `extensions.md`, `macbook-setup.md`).

| Profil / limit | Maks. temp. | Takt pod opterećenjem | Throttle brojač |
|---|---|---|---|
| power-saver (30 s) | ~63 °C | 0,8–1,2 GHz | bez promene |
| balanced (2,5 GHz, 30 s) | 79–83 °C | 2,49 GHz | bez promene |
| performance 2800 MHz (60 s, čist test) | 89–97 °C | ~2,8 GHz | bez promene |
| performance 3700 MHz (30–180 s) | 99–100 °C | 2,8–3,1 GHz | +58000 do +65000 po testu |

- **Zaključak: 2800 MHz je izabrana „zlatna sredina“ za performance** (~12% iznad balanced, bez termalnog throttlinga u 60 s). `perf-max-khz` je tada bio `2800000`; trenutno je `3000000` (korisnik ga je podigao posle mešanog testa, vidi niže). Limiti oko 2600 MHz su mereni samo u nečistim testima (klizač pomeran tokom testa).
- Ograničenja: testovi traju 30–60 s (duže opterećenje nije mereno), `avgMHz` je trenutni prosek iz `/proc/cpuinfo` pa može preći limit, a sa starom pastom/prašinom se vrednosti mogu poboljšati posle čišćenja i repastiranja (nije urađeno; mirovanje ~55–61 °C).
- Ponavljanje: samo čitanje sysfs-a i `stress-ng --cpu $(nproc) --timeout 60` (ekvivalent starog `stress --cpu`; `stress` je zamenjen, vidi „Uklonjeno“ u `macbook-setup.md`); ne treba root.

## Mešani test CPU + RAM (`stress-ng`, 2026-10-17)

Ista mašina i kernel, profil performance. Uzorkovanje na 5 s: ukupna CPU upotreba iz `/proc/stat`, `x86_pkg_temp`, takt, ventilator, `thermal_throttle` brojač, zauzeta RAM.

| Komanda (60 s) | Ukupni CPU | Maks. temp. | Takt | Throttle |
|---|---|---|---|---|
| `stress-ng -c 8 -l 70 -m 2 --vm-bytes 1G -t 60 -M` | ~94–98% | 100 °C | 2,5–3,3 GHz | ~+8000 |
| `stress-ng -c 8 -l 45 -m 2 --vm-bytes 1G -t 60 -M` (dva runa) | 72–79% | 99–100 °C | 2,2–3,0 GHz | +6216 / +760 |

- **`-l` važi samo za CPU worker-e, VM worker-i ga ignorišu** (~99% jezgra po instanci). Ukupno opterećenje je zato zbir: 8 × l% + 2 × ~1 jezgro. Za ukupno ~70% treba `-l 45`, a ne `-l 70`.
- Ventilator ~6150 RPM celo vreme (maksimum), temperatura posle testa pada na ~65 °C za ~5 s. To je očekivano zbog male toplotne mase čipa i ništa ne govori o stanju paste; paste utiče na rast temperature pod opterećenjem.
- Limit frekvencije (klizač) pomeran je tokom runova, pa su takt i throttle neuporedivi između njih. Okvirna „zlatna sredina“ za performance je 2800–3000 MHz.
- Ponavljanje: komande iz tabele, bez roota; uzorkuje se sysfs i `/proc/stat`. Razdvajanje uzroka toplote (prašina/pasta) traži mirovanje posle 10 min i isti test na fiksnom taktu pre i posle čišćenja.

## Sweep limita frekvencije, skill `cpu-stress-test` (2026-10-17)

Ista mašina i kernel, na punjaču, profil performance, `stress-ng -c 8 --cpu-method matrixprod`. Po limitu: hlađenje do ~60 °C, pa 3 faze od 30 s: steady (`-l 30`), bursty (5 s 100% / 5 s mirovanje), sustained (100%). Skill i skripta: `claude-config.md`.

Sustained (100%):

| Limit (MHz) | Maks. temp. | Stvarni takt | Throttle | bogo ops/s | vs 2500 |
|---|---|---|---|---|---|
| 2500 | 81 °C | 2494 | 0 | 3837 | – |
| 2800 | 92 °C | 2793 | 0 | 4383 | +14% |
| 3000 | 99 °C | 2955 | 2802 | 4488 | +17% |
| 3300 | 100 °C | 2911 | 8470 | 4454 | +16% |
| 3700 | 100 °C | 2964 | 9868 | 4500 | +17% |

- Bursty (bogo ops/s): 3868, 4349, 4596, 4686, 4724 (+12% na 2800, +22% na 3700), throttle 0 do 2800, 2802 sustained na 3000. Steady na 3300 i 3700: maks. 99–100 °C i throttle (674 / 6786) i pri 30% opterećenja.
- **Zaključak: iznad 3000 MHz stvarni takt ne raste (~2,9–3,0 GHz), limit nije ograničavajući nego toplota.** Preporuka za performance je 2800 MHz (+14%, bez throttlinga, 92 °C); 3000 MHz je granica (+2,5% više, 99 °C, throttle); 3300 i 3700 nemaju smisla na ovom hlađenju.
- Ograničenja: 30 s po fazi ne dostiže termalnu ravnotežu (temperatura na 2800 u dužem radu je verovatno viša), faze idu redom pa sustained počinje zagrejan, mirovanje ~57–60 °C, prašina i pasta nisu čišćeni.

## Trajanje boota

Trenutno **14,2 s** (2,0 s kernel + 12,2 s userspace; pre izmene 23,6 s). Uzrok je bio `gpu-manager.service` (10,4 s): čekao je NVIDIA udev pravila koja nikad ne stižu, a `gdm.service` ima `After=gpu-manager.service`. Najsporije je sada `gdm.service` (5,1 s), pa `snapd` (~2,5 s), sve paralelno.

- Mera: `gpu-manager.service` maskiran (vidi „Isključeni servisi“ u `macbook-setup.md`).

## Instalirani softver (popis 2026-10-13; Ubuntu 26.04.1, kernel 7.0.0-38)

**apt (ručno instalirano):**
- Razvoj: `git`, `build-essential`, `gcc`, `g++`, `nasm`, `pkg-config`, `checkinstall`, `dkms`, `code` (.deb), `openjdk-17-jdk-headless`, `python-is-python3`, `pipx`, `docker-ce` + `containerd.io`, `mongodb-mongosh`, `pgadmin4-desktop`, `xvfb`, `adb`
- Hardver i sistem: `broadcom-sta-dkms`, `mbpfan`, `lm-sensors`, `powertop`, `intel-gpu-tools`, `vainfo`, `mesa-utils`, `efibootmgr`, `gparted`, `kyocera-sane`, `stress-ng`, `systemd-zram-generator`, `zenity`
- Aplikacije: `google-chrome-stable`, `vlc`, `transmission`, `copyq`, `imagemagick`, `simple-scan`, `htop`, `autojump`, `screen`, `curl`
- Ostalo: `ibus-table-cangjie*`, `xfonts-cyrillic`, `xfonts-scalable`, `wbritish`

**Snap:** ručno `cheese`, `remmina`, `solvespace` (ostaju namerno); ostalo uz sistem. Flatpak nije instaliran.

**Van paketnih menadžera:** `/usr/local/bin` (`go`, `kubectl`, `helm`, `nosqlbooster4mongo`, `frontProxy`, `lowjson`; uz njih `go.new`, `helm3.15.2`, `kubectl1.30`), `~/.local/bin` (`claude`), `~/go/bin` (`gopls`, `golangci-lint`, `staticcheck`), npm globalno (`typescript`, `ts-node`), `~/.nvm`, `~/Android/Sdk`. Python je samo sistemski `python3.14`.

**apt repozitorijumi** (`resolute`): `ubuntu.sources`, `ubuntu-esm-apps`, `ubuntu-esm-infra`, `google-chrome`, `vscode`, `docker.sources`, `pgadmin4.sources`.

Ponavljanje popisa: `apt-mark showmanual; snap list; apt list --installed 2>/dev/null | grep ',local\]'; ls /usr/local/bin /opt ~/.local/bin ~/go/bin`.
