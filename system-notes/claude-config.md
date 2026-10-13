# Claude Code

Naše izmene Claude Code-a (hookovi, modovi, permission pravila, helperi), svaka u svom `##` odeljku; samo konačno stanje.

## Podsetnici pri startu (SessionStart hook)

Pri svakom startu i `--resume` prikazuje listu iz `~/.claude/CLAUDE.md` (sekcija „Reminder list“); ako je prazna, piše „Nema ništa.“

- Skripta: `~/.claude/reminders-hook.py`; hook je u `~/.claude/settings.json` (`hooks.SessionStart`, matcher `startup|resume`).
- Zamenjuje `cc` alias (obrisan iz `~/.bash_aliases`) i stari „reminders“ mod (`~/.claude/dev-mods/.../reminders`) sa `~/.claude/reminders.md`.
- Vraćanje: ukloniti ključ `hooks` iz `~/.claude/settings.json` (ili vratiti `~/.claude/backups/settings.json.pre-reminders-hook`) i obrisati `~/.claude/reminders-hook.py`.

## run-preview mod (traka iznad prompta)

Traka „run.sh ready“ iznad prompta: hover preko dugmeta „Show script“ prikazuje sadržaj `$XDG_RUNTIME_DIR/run.sh` (do 30 linija), klik na njega ga ispisuje u transkript, „Copy run line“ kopira liniju `bash $XDG_RUNTIME_DIR/run.sh` (bez `!`, za običan terminal), „Delete script“ briše `$XDG_RUNTIME_DIR/run.sh` (bez potvrde). Miš (klik i hover) radi samo u fullscreen modu (`/tui fullscreen` ili `CLAUDE_CODE_NO_FLICKER=1`); u običnom modu dugmad i hover ne reaguju.

- Fajlovi: `~/.claude/skills/run-preview/` (`.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/register.tsx`, `types/index.d.ts` za stanje `rev` koje posle brisanja skripte pokreće ponovno iscrtavanje trake); Claude Code ga sam učitava iz skills foldera, u svakoj sesiji.
- Radi samo u interaktivnom terminalu (u pozadinskim sesijama se traka ne iscrtava). Posle izmene: `/reload-plugins`.
- Vraćanje: obrisati `~/.claude/skills/run-preview/`.

## Sudo preko grafičkog prozora za lozinku (askpass)

Claude Code nema terminal, pa `sudo` ne može sam da pita za lozinku. Rešenje: `sudo -A` pokreće helper koji na ekranu otvara `zenity` prozor; lozinku ukucava korisnik, Claude je ne vidi.

- Helper: `~/.local/bin/sudo-askpass` (`chmod 700`, `exec zenity --password`). Poziv: `SUDO_ASKPASS=$HOME/.local/bin/sudo-askpass sudo -A <komanda>`.
- Permission pravilo `Bash(SUDO_ASKPASS=* sudo -A *)` je u `~/.claude/settings.json` (`permissions.allow`); dodato ručno preko `/permissions`, jer Claude ne sme sam da menja svoja pravila. Pravilo je široko: dozvoljava svaku `sudo -A` komandu, a lozinka ostaje jedina zaštita.
- Radi samo kad je korisnik ispred mašine (prozor se otvara na `DISPLAY`/Wayland sesiji).
- Vraćanje: obrisati `~/.local/bin/sudo-askpass` i pravilo iz `~/.claude/settings.json` (`/permissions` → Allow → Delete).
