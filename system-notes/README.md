# System notes

Beleške o izmenama sistema na ovom laptopu: šta je promenjeno, zašto i kako se vraća.

**Beleške se bave isključivo Ubuntuom.** Drugi operativni sistemi na ovoj mašini (dual-boot) ne pominju se, osim ako korisnik to izričito ne zatraži.

Sve naše ekstenzije (GNOME ekstenzije, Claude Code hookovi/modovi) beleže se u `extensions.md`, svaka u svom `##` odeljku (samo konačno stanje: šta radi, fajlovi, aktivacija, vraćanje).

Rezultati svih analiza (potrošnja, popis softvera i slično) idu u `analysis.md`, svaka u svom `##` odeljku.

- [macbook-setup.md](macbook-setup.md) — kritična pravila (NVIDIA/grafika: dva režima grafike preko `nv-nvidia on|off` (A: Intel, B: NVIDIA + HDMI), stanje `nv-nvidia status`; `/sys/power/disk` ostaje `platform`, swap samo preko `nv-hibernate`, zram swap, mbpfan, PowerTOP) i rešene izmene sa vraćanjem: grafika i hlađenje, potrošnja i Wi-Fi, hibernacija, logind, Bluetooth, kamera
- [analysis.md](analysis.md) — rezultati analiza: potrošnja baterije, trajanje boota (23,6 → 14,2 s), popis instaliranog softvera i čišćenje (sa vraćanjem)
- [extensions.md](extensions.md) — GNOME ekstenzije `battery-watts` i `hibernate-menu` i Claude Code SessionStart hook za podsetnike
