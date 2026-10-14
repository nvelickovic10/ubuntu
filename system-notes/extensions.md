# Ekstenzije (GNOME)

## Battery Watts (GNOME ekstenzija `battery-watts@local`)

Prikazuje snagu punjenja/pražnjenja u vatima (`+33.8 W`, `−12.1 W`, `x W` kad je puna/miruje), a iza nje temperaturu procesora i prosečnu/maksimalnu frekvenciju jezgara (`−12.1 W · 62 °C · 0.8/1.6 GHz`).

- Gde: labela u sistemskoj grupi ikonica u gornjoj traci, odmah desno od sistemske baterije (`BatteryIndicator` je `SystemIndicator`, dodat preko `quickSettings.addExternalIndicator`). Klik na grupu otvara karticu u quick settings meniju: status, nivo, preostalo vreme, snaga, struja, napon, temperatura baterije, temperatura i frekvencija procesora, zdravlje baterije i broj ciklusa.
- Temperatura procesora: thermal zona `x86_pkg_temp` (`/sys/class/thermal/thermal_zone*/temp`), traži se po tipu; ista vrednost je i red "CPU temperature" u kartici.
- Frekvencija: `prosek/max`, gde je prosek srednja vrednost `scaling_cur_freq` svih jezgara, a max trenutni `scaling_max_freq` (limit, npr. 1.6 GHz na Power Saveru); jedna decimala u traci, dve u redu "CPU frequency (avg/max)" kartice. Pošto je `intel_pstate` u passive režimu, prosek je frekvencija koju kernel traži, ne izmerena.
- Izvor: `/sys/class/power_supply/BAT0` (`current_now × voltage_now`, ova baterija nema `power_now`). Osvežava se na 2 s.
- Raspored ikonica (`_reorder` u `extension.js`), zdesna nalevo: sistemska grupa, jezik, caffeine, copyq, accessibility. Unutar sistemske grupe baterija je skroz levo. Pri `disable()` se ikona vraća na kraj grupe.
- Procenat u kartici je sysfs `capacity` (u odnosu na fabrički kapacitet), pa može biti veći od sistemskog (UPower računa `charge_now / charge_full`).
- Fajlovi: `~/.local/share/gnome-shell/extensions/battery-watts@local/` (`metadata.json`, `extension.js`).
- Aktivacija: UUID je u `org.gnome.shell enabled-extensions`; `org.gnome.shell disable-user-extensions` mora biti `false` (bio je `true` i blokirao je učitavanje). Na Waylandu je za novu verziju potrebna odjava/prijava.
- Vraćanje: `gnome-extensions disable battery-watts@local`, obrisati direktorijum ekstenzije (po želji i UUID iz `enabled-extensions`). Prethodne verzije `extension.js` (zasebno dugme sa popup-om) nisu sačuvane.

## Hibernate Menu (GNOME ekstenzija `hibernate-menu@local`)

Dodaje stavku **Hibernate** u sistemski power meni, odmah posle Suspend (klik zove `org.freedesktop.login1.Manager.Hibernate`). Meni je `Main.panel.statusArea.quickSettings._system._systemItem.menu` (GNOME 50).

- Zahteva polkit pravilo `/etc/polkit-1/rules.d/10-allow-hibernate.rules` (Ubuntu zabranjuje hibernaciju; pravilo je dozvoljava grupi `sudo`). Bez njega: `Access denied`.
- Fajlovi: `~/.local/share/gnome-shell/extensions/hibernate-menu@local/` (`metadata.json`, `extension.js`). Aktivacija: UUID u `org.gnome.shell enabled-extensions`; na Waylandu odjava/prijava.
- Uključivanje/isključivanje cele hibernacije (ekstenzija, swap, resume konfiguracija): `nv-hibernate on|off`, vidi `macbook-setup.md` i `~/Documents/ubuntu/CLAUDE.md`.
- Vraćanje: `gnome-extensions disable hibernate-menu@local`, obrisati direktorijum ekstenzije i `sudo rm /etc/polkit-1/rules.d/10-allow-hibernate.rules`.

## Power Saver Frequency (GNOME ekstenzija `powersaver-freq@local`)

Klizač u Quick Settings-u (meni gore desno) za maksimalnu CPU frekvenciju koja važi na profilu Power Saver: 800–2500 MHz u koracima od 100 MHz. Kartica (`QuickSettingsItem`, ne `QuickSlider`): gore ikonica, naslov i vrednost (npr. `1600 MHz`), ispod klizač pune širine; nema podmeni ni strelicu.

- Ekstenzija samo upisuje kHz u `/var/lib/turbo-follow-profile/saver-max-khz` (direktorijum pripada korisniku `monrasta`, upis sa zakašnjenjem od 300 ms). Frekvenciju zaista postavlja `turbo-follow-profile.service` (vidi `macbook-setup.md`): proveri vrednost, ograniči je i primeni u roku od 2 s ako je Power Saver aktivan.
- Fajlovi: `~/.local/share/gnome-shell/extensions/powersaver-freq@local/` (`metadata.json`, `extension.js`). Aktivacija: UUID u `org.gnome.shell enabled-extensions`; na Waylandu odjava/prijava. Greške: `journalctl -b /usr/bin/gnome-shell`.
- Vraćanje: `gnome-extensions disable powersaver-freq@local` i obrisati direktorijum ekstenzije; limit se tada menja samo ručnim upisom u `saver-max-khz`.
