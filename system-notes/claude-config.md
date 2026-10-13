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

## Isključeni claude.ai konektori

Svi claude.ai konektori (Claude Docs, Cloudflare, Epidemic Sound, Gmail, Calendar, Drive, HubSpot, Slack) su isključeni jer se ne koriste; svaki je trošio kontekst na `authenticate` stubove i instrukcije (oko 7k tokena po sesiji).

- Podešavanje: `env.ENABLE_CLAUDEAI_MCP_SERVERS = "false"` u `~/.claude/settings.json`; važi od sledećeg starta sesije.
- Vraćanje: obrisati taj ključ iz `env` (ili vratiti `~/.claude/backups/settings.json.pre-no-connectors`). Pojedinačno se konektori i dalje mogu uključiti u `/mcp` samo ako je varijabla uklonjena.

## health-bars mod (limiti i context kao health bar)

Jedan red iznad prompta sa trakama `SESSION` (5h prozor), `WEEKLY` (7d prozor) i `CONTEXT` (popunjenost context prozora), jedna pored druge (prelamaju se ako je terminal uzak). Svaka traka ima 12 blokova, pokazuje šta je ostalo (prazni se kako trošiš limit) i procenat preostalog.

- **Boje** su fiksne (hex, ne tema): SESSION crvena, WEEKLY žuta; CONTEXT je podeljen na trećine (po 4 bloka: crveno, žuto, zeleno, sleva udesno; prazni se zdesna, pa crveno ostaje poslednje). Prazni deo trake je zatamnjen.
- **SESSION i WEEKLY** pokazuju i vreme do reseta. Ne crtaju se dok nema podataka (van pretplate ili pre prvog odgovora). Posle `/clear` i novog starta ostaju poslednje poznate vrednosti (čuvaju se u `$.store` pod ključem `limits`, jer se atom session stanja prazni na `/clear`); prozor čije je vreme reseta prošlo crta se kao nepotrošen.
- **CONTEXT** je uvek tu. Pored procenta stoji popunjenost i veličina prozora (npr. `71k/1M`; bez čitanja `0k/1M`), pa zatamnjeno model i effort (npr. `sonnet-5-5 · high`). Model se čita pri svakom iscrtavanju (prati `/model`). Effort se beleži iz poslednjeg zahteva glavne petlje (`turn.step`, bez subagenata; korak bez effort-a ništa ne menja) i čuva u `$.store` pod ključem `effort` zajedno sa modelom, pa ostaje posle `/clear` ili starta; važi samo dok je model isti, a nema ga za model bez effort-a ili dok ništa nije zabeleženo. Dok nema podatka (nova sesija, posle `/compact`) traka pokazuje 100%.
- **Podaci:** `session.measure` hook (`rateLimits`, `context.percent`), početno stanje iz `$.session.usage()` pri `session.start`.
- **Podsetnici:** skroz desno u istom redu je `⏰ N`, broj podsetnika iz liste u `~/.claude/CLAUDE.md` (sekcija „Reminder list“, ista koju čita SessionStart hook; čita se pri svakom iscrtavanju). Klik na broj (toggle) otvara/zatvara celu listu iznad reda, poravnatu udesno. Ispred svakog podsetnika je dugme „✕“: klik ga briše iz `~/.claude/CLAUDE.md` (fajl se pri kliku ponovo čita) i prikazuje toast; kad se obriše poslednji, upisuje se `- (empty)`. Klik radi samo u fullscreen modu.
- **Fajlovi:** `~/.claude/skills/health-bars/` (`.claude-plugin/plugin.json`, `hooks/register.tsx`, `types/index.d.ts`, `tests/band.test.ts`); Claude Code ga sam učitava iz skills foldera, u svakoj sesiji. Testovi: `claude plugin test <folder>`; posle izmene: `/reload-plugins`.
- **Vraćanje:** obrisati `~/.claude/skills/health-bars/`.
