# System notes

Beleške o izmenama sistema na ovom laptopu: šta je promenjeno, zašto i kako se vraća.

**Beleške se bave isključivo Ubuntuom.** Drugi operativni sistemi na ovoj mašini (dual-boot) ne pominju se, osim ako korisnik to izričito ne zatraži.

Naše GNOME ekstenzije beleže se u `extensions.md`, a naše izmene Claude Code-a (hookovi, modovi, permission pravila, helperi) u `claude-config.md`; svaka u svom `##` odeljku (samo konačno stanje: šta radi, fajlovi, aktivacija, vraćanje).

Rezultati svih analiza (potrošnja, popis softvera i slično) idu u `analysis.md`, svaka u svom `##` odeljku.

- [macbook-setup.md](macbook-setup.md) — kritična pravila (ne diraj) i izmene sa vraćanjem: grafika (dva režima, `nv-nvidia`) i hlađenje, potrošnja i ventilatori, hibernacija (`nv-hibernate`), zram swap, kamera, logind (uz lid-ignore na performance), Bluetooth, turbo i CPU limit po power profilu
- [analysis.md](analysis.md) — rezultati analiza: potrošnja baterije, trajanje boota, popis instaliranog softvera i čišćenje (sa vraćanjem)
- [extensions.md](extensions.md) — GNOME ekstenzije `battery-watts` i `hibernate-menu`
- [claude-config.md](claude-config.md) — Claude Code: run-preview mod, izlaz uživo za run.sh (`nv-live`), askpass helper (zenity, nekorišćen), isključeni claude.ai konektori, health-bars mod, blokada sudo-a, skillovi sudo-run i system-notes, čišćenje `dev-mods`
