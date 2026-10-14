# System notes

Beleške o izmenama sistema na ovom laptopu: šta je promenjeno, zašto i kako se vraća.

**Beleške se bave isključivo Ubuntuom.** Drugi operativni sistemi na ovoj mašini (dual-boot) ne pominju se, osim ako korisnik to izričito ne zatraži.

## Gde šta ide

- **`macbook-setup.md`**: sve što menja sam sistem (drajveri, boot, grafika, servisi, napajanje, hlađenje, uređaji, podešavanja Ubuntua). Ako ne pripada nijednom od ostalih fajlova, ide ovde.
- **`extensions.md`**: naše GNOME ekstenzije.
- **`claude-config.md`**: naše izmene Claude Code-a (hookovi, modovi, skillovi, permission pravila, pomoćne skripte).
- **`analysis.md`**: rezultati analiza i popisa (potrošnja, trajanje boota, instalirani softver) i čišćenja koja iz njih proističu.

Svaka tema ima svoj `##` odeljak, a u njemu samo konačno stanje: šta radi, koji su fajlovi, kako se aktivira i kako se vraća. Kad fajl dobije ili izgubi temu, ažurirati indeks ispod.

## Indeks

- [macbook-setup.md](macbook-setup.md) — kritična pravila (ne diraj) i izmene sa vraćanjem: grafika (dva režima, `nv-nvidia`) i hlađenje, potrošnja i ventilatori, hibernacija (`nv-hibernate`), zram swap, kamera, logind (uz lid-ignore na performance), Bluetooth, turbo i CPU limit po power profilu
- [analysis.md](analysis.md) — rezultati analiza: potrošnja baterije, trajanje boota, popis instaliranog softvera i čišćenje (sa vraćanjem)
- [extensions.md](extensions.md) — GNOME ekstenzije `battery-watts`, `hibernate-menu` i `powersaver-freq`
- [claude-config.md](claude-config.md) — Claude Code: run-preview mod, izlaz uživo za run.sh (`nv-live`), askpass helper (zenity, nekorišćen), isključeni claude.ai konektori, health-bars mod, blokada sudo-a, skillovi sudo-run, system-notes i remind, čišćenje `dev-mods`
