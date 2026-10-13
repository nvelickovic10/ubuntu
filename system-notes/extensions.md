# Ekstenzije (GNOME)

## Battery Watts (GNOME ekstenzija `battery-watts@local`)

Prikazuje snagu punjenja/pražnjenja u vatima (`+33.8 W`, `−12.1 W`, `x W` kad je puna/miruje).

- Gde: labela u sistemskoj grupi ikonica u gornjoj traci, odmah desno od sistemske baterije (`BatteryIndicator` je `SystemIndicator`, dodat preko `quickSettings.addExternalIndicator`). Klik na grupu otvara karticu u quick settings meniju: status, nivo, preostalo vreme, snaga, struja, napon, temperatura, zdravlje baterije i broj ciklusa.
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
