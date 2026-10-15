# Ekstenzije (GNOME)

## Battery Watts (GNOME ekstenzija `battery-watts@local`)

Prikazuje snagu punjenja/pražnjenja u vatima (`+33.8 W`, `−12.1 W`, `x W` kad je puna/miruje), a iza nje temperaturu procesora i prosečnu/maksimalnu frekvenciju jezgara (`−12.1 W · 62 °C · 0.8/1.6 GHz`).

- Gde: labela u sistemskoj grupi ikonica u gornjoj traci, odmah desno od sistemske baterije (`BatteryIndicator` je `SystemIndicator`, dodat preko `quickSettings.addExternalIndicator`). Klik na grupu otvara karticu u quick settings meniju: status, nivo, preostalo vreme, snaga, struja, napon, temperatura baterije, temperatura i frekvencija procesora, zdravlje baterije i broj ciklusa.
- Temperatura procesora: thermal zona `x86_pkg_temp` (`/sys/class/thermal/thermal_zone*/temp`), traži se po tipu; ista vrednost je i red "CPU temperature" u kartici.
- Frekvencija: `prosek/max`, gde je prosek srednja vrednost `scaling_cur_freq` svih jezgara, a max trenutni `scaling_max_freq` (limit, npr. 1.6 GHz na Power Saveru); jedna decimala u traci, dve u redu "CPU frequency (avg/max)" kartice. Pošto je `intel_pstate` u passive režimu, prosek je frekvencija koju kernel traži, ne izmerena.
- Izvor: `/sys/class/power_supply/BAT0` (`current_now × voltage_now`, ova baterija nema `power_now`). Osvežava se na 2 s.
- Raspored ikonica (`_reorder` u `extension.js`), zdesna nalevo: sistemska grupa, jezik, copyq, accessibility. Unutar sistemske grupe baterija je skroz levo. Pri `disable()` se ikona vraća na kraj grupe.
- Procenat u kartici je sysfs `capacity` (u odnosu na fabrički kapacitet), pa može biti veći od sistemskog (UPower računa `charge_now / charge_full`).
- Fajlovi: `~/.local/share/gnome-shell/extensions/battery-watts@local/` (`metadata.json`, `extension.js`).
- Aktivacija: UUID je u `org.gnome.shell enabled-extensions`; `org.gnome.shell disable-user-extensions` mora biti `false` (inače se ekstenzije ne učitavaju). Na Waylandu je za novu verziju potrebna odjava/prijava.
- Vraćanje: `gnome-extensions disable battery-watts@local`, obrisati direktorijum ekstenzije (po želji i UUID iz `enabled-extensions`).

## Hibernate Menu (GNOME ekstenzija `hibernate-menu@local`)

Dodaje stavku **Hibernate** u sistemski power meni, odmah posle Suspend (klik zove `org.freedesktop.login1.Manager.Hibernate`). Meni je `Main.panel.statusArea.quickSettings._system._systemItem.menu` (GNOME 50).

- Zahteva polkit pravilo `/etc/polkit-1/rules.d/10-allow-hibernate.rules` (Ubuntu zabranjuje hibernaciju; pravilo je dozvoljava grupi `sudo`). Bez njega: `Access denied`.
- Fajlovi: `~/.local/share/gnome-shell/extensions/hibernate-menu@local/` (`metadata.json`, `extension.js`). Aktivacija: UUID u `org.gnome.shell enabled-extensions`; na Waylandu odjava/prijava.
- Uključivanje/isključivanje cele hibernacije (ekstenzija, swap, resume konfiguracija): `nv-hibernate on|off`, vidi `macbook-setup.md` i `~/Documents/ubuntu/CLAUDE.md`.
- Vraćanje: `gnome-extensions disable hibernate-menu@local`, obrisati direktorijum ekstenzije i `sudo rm /etc/polkit-1/rules.d/10-allow-hibernate.rules`.

## Power Saver Frequency (GNOME ekstenzija `powersaver-freq@local`)

Klizač u Quick Settings-u (meni gore desno) za maksimalnu CPU frekvenciju koja važi na profilu Power Saver: 800–2500 MHz u koracima od 100 MHz. Kartica (`QuickSettingsItem`, ne `QuickSlider`): gore ikonica, naslov i vrednost (npr. `1600 MHz`), ispod klizač pune širine; nema podmeni ni strelicu. Kartica je vidljiva samo dok je aktivan profil Power Saver (prati `ActiveProfile` preko D-Bus proxyja na `net.hadess.PowerProfiles`).

- **Svetlina:** pri prelasku na Power Saver ekstenzija pamti trenutnu svetlinu u `~/.cache/powersaver-freq/saved-brightness` i spušta je na 10% (ako je već niža, ne dira je), a pri izlasku je vraća i briše fajl (fajl postoji samo dok je svetlina spuštena, pa dupli signali ne smetaju; pri učitavanju ekstenzije svetlina se ne menja). Postavlja se preko `Main.brightnessManager.globalScale.value` (0–1), ne preko sysfs-a, jer samo tako klizač svetline u Quick Settings-u prati promenu (GNOME 50 ga vezuje za `globalScale`). Prag je `SAVER_BRIGHTNESS` u `extension.js`.
- **Osvetljenje tastature:** pri prelasku na Power Saver ekstenzija pamti trenutnu vrednost u `~/.cache/powersaver-freq/saved-kbd-backlight` i gasi ga (UPower `KbdBacklight.SetBrightness(0)`, ako je već ugašeno ne dira ga), a pri izlasku ga vraća i briše fajl. Menja se samo pri stvarnoj promeni profila, kao i svetlina ekrana.
- Ekstenzija upisuje kHz u `/var/lib/turbo-follow-profile/saver-max-khz` (direktorijum pripada korisniku `monrasta`, upis sa zakašnjenjem od 300 ms). Frekvenciju zaista postavlja `turbo-follow-profile.service` (šta radi i koliko brzo: „Turbo i CPU frekvencija po power profilu“ u `macbook-setup.md`).
- **Idle:** ekstenzija preko `global.backend.get_core_idle_monitor()` (idle watchevi `IDLE_MS` = 15000 i `IDLE_LONG_MS` = 30000 + user-active watch) upisuje nivo `1`/`2`/`0` u `/var/lib/turbo-follow-profile/idle`; pri `disable()` upisuje `0`. Šta servis radi sa nivoom: isti odeljak u `macbook-setup.md`.
- Fajlovi: `~/.local/share/gnome-shell/extensions/powersaver-freq@local/` (`metadata.json`, `extension.js`). Aktivacija: UUID u `org.gnome.shell enabled-extensions`; na Waylandu odjava/prijava. Greške: `journalctl -b /usr/bin/gnome-shell`.
- Vraćanje: `gnome-extensions disable powersaver-freq@local` i obrisati direktorijum ekstenzije; limit se tada menja samo ručnim upisom u `saver-max-khz`.

## mbpfan Thresholds (GNOME ekstenzija `mbpfan-thresholds@local`)

Kartica u Quick Settings-u sa tri klizača (40–90 °C, razmak najmanje 2 °C, susedni se pomeraju) za `low_temp`, `high_temp` i `max_temp` iz `/etc/mbpfan.conf` (značenje i vrednosti: „Potrošnja i ventilatori“ u `macbook-setup.md`). Uvek vidljiva. Ekstenzija 800 ms posle poslednjeg pomeranja upisuje `low high max` u `/var/lib/mbpfan-ui/thresholds` (direktorijum pripada korisniku `monrasta`).

- **Root strana:** `mbpfan-apply.path` (enabled, `PathChanged` na taj fajl) pokreće `mbpfan-apply.service` (oneshot, `/usr/local/sbin/mbpfan-apply`). Skripta prihvata samo tri dvocifrena cela broja sa `low >= 40`, `max <= 90`, `low < high < max`, sa `sed` menja samo te tri vrednosti u konfiguraciji i restartuje `mbpfan`. Fajl piše običan korisnik, pa je ta validacija jedina zaštita: ništa drugo ne može dospeti u `/etc/mbpfan.conf`.
- **Provera:** upisati `56 61 71` u `/var/lib/mbpfan-ui/thresholds` (preko rename-a, kao ekstenzija) i posle 3 s `grep -E '^(low|high|max)_temp' /etc/mbpfan.conf` mora pokazati 56/61/71 (2026-10-15, provereno, pa vraćeno na 55/60/70). Sama ekstenzija (UI) još nije provereno učitana.
- **Aktivacija:** `gnome-extensions enable mbpfan-thresholds@local`; na Waylandu odjava/prijava. Greške: `journalctl -b /usr/bin/gnome-shell`.
- **Vraćanje:** `gnome-extensions disable mbpfan-thresholds@local && rm -r ~/.local/share/gnome-shell/extensions/mbpfan-thresholds@local`, pa root deo: `sudo systemctl disable --now mbpfan-apply.path && sudo rm -r /etc/systemd/system/mbpfan-apply.path /etc/systemd/system/mbpfan-apply.service /usr/local/sbin/mbpfan-apply /var/lib/mbpfan-ui && sudo systemctl daemon-reload`. Konfiguracija ostaje na poslednjim vrednostima.
