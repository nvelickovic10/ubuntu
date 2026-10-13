# Claude Code

Naše izmene Claude Code-a (hookovi, modovi, permission pravila, helperi), svaka u svom `##` odeljku; samo konačno stanje.

## Podsetnici pri startu (SessionStart hook)

Pri svakom startu i `--resume` prikazuje listu iz `~/.claude/CLAUDE.md` (sekcija „Reminder list“); ako je prazna, piše „Nema ništa.“

- Skripta: `~/.claude/reminders-hook.py`; hook je u `~/.claude/settings.json` (`hooks.SessionStart`, matcher `startup|resume`).
- Zamenjuje `cc` alias (obrisan iz `~/.bash_aliases`) i stari „reminders“ mod (`~/.claude/dev-mods/.../reminders`) sa `~/.claude/reminders.md`.
- Vraćanje: ukloniti ključ `hooks` iz `~/.claude/settings.json` (ili vratiti `~/.claude/backups/settings.json.pre-reminders-hook`) i obrisati `~/.claude/reminders-hook.py`.

## run-preview mod (traka iznad prompta)

Traka „run.sh ready“ iznad prompta za `$XDG_RUNTIME_DIR/run.sh`, skriptu koju Claude piše kad korisnik treba nešto da pokrene (sudo). Dugmad:

- „Show script“: hover prikazuje sadržaj skripte (do 30 linija), klik ga ispisuje u transkript.
- „Accept“: pokreće skriptu (do 10 minuta) tako da svaki `sudo` u njoj postaje `sudo -A`, pa se lozinka traži u zenity prozoru (`~/.local/bin/sudo-askpass`, vidi odeljak ispod). Posle izvršenja skripta se briše, a Claude dobija poruku sa exit kodom, stdout i stderr (poslednjih 4000 znakova) i nastavlja sam. Dok radi, traka piše „running...“.
- „Decline“: briše skriptu (bez potvrde) i javlja Claude-u da je odbijena i da je ne pokreće.
- „Copy run line“: kopira `bash $XDG_RUNTIME_DIR/run.sh` (bez `!`, za običan terminal).

Miš (klik i hover) radi samo u fullscreen modu (`/tui fullscreen` ili `CLAUDE_CODE_NO_FLICKER=1`); u običnom modu dugmad i hover ne reaguju. Accept je potvrđen u radu: zenity prozor se otvara i izlaz stiže do Claude-a.

- Fajlovi: `~/.claude/skills/run-preview/` (`.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/register.tsx`, `types/index.d.ts` za stanje `rev` (ponovno iscrtavanje trake posle brisanja skripte) i `busy` (skripta trenutno radi)); Claude Code ga sam učitava iz skills foldera, u svakoj sesiji.
- Radi samo u interaktivnom terminalu (u pozadinskim sesijama se traka ne iscrtava) i kad je korisnik ispred mašine (zenity prozor). Posle izmene: `/reload-plugins`.
- Vraćanje: obrisati `~/.claude/skills/run-preview/`.

## Sudo preko grafičkog prozora za lozinku (askpass)

Claude Code nema terminal, pa `sudo` ne može sam da pita za lozinku. Rešenje: `sudo -A` pokreće helper koji na ekranu otvara `zenity` prozor; lozinku ukucava korisnik, Claude je ne vidi.

- Helper: `~/.local/bin/sudo-askpass` (`chmod 700`, `exec zenity --password`). Poziv: `SUDO_ASKPASS=$HOME/.local/bin/sudo-askpass sudo -A <komanda>`.
- Permission pravilo `Bash(SUDO_ASKPASS=* sudo -A *)` je u `~/.claude/settings.json` (`permissions.allow`); dodato ručno preko `/permissions`, jer Claude ne sme sam da menja svoja pravila. Pravilo je široko: dozvoljava svaku `sudo -A` komandu, a lozinka ostaje jedina zaštita.
- Radi samo kad je korisnik ispred mašine (prozor se otvara na `DISPLAY`/Wayland sesiji).
- Vraćanje: obrisati `~/.local/bin/sudo-askpass` i pravilo iz `~/.claude/settings.json` (`/permissions` → Allow → Delete).
