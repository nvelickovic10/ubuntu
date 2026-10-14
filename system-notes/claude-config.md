# Claude Code

## run-preview mod (traka iznad prompta)

Traka „run.sh ready“ iznad prompta za `$XDG_RUNTIME_DIR/claude-scripts/run-<PID>.sh` (`/run/user/1000/claude-scripts`, mod 0700) (svaka sesija ima svoj fajl, pa se paralelne sesije ne prepisuju; `<PID>` je PID Claude procesa sesije: u Bash-u je to `$CLAUDE_PID`, a mod ga dobija kao `$PPID` procesa koji sam pokrene (`$.env.get` ne vidi `CLAUDE_CODE_SESSION_ID`, potvrđeno 2026-10-14); ako to ne uspe, pada na `claude-scripts/run.sh`), skriptu koju Claude piše kad korisnik treba nešto da pokrene (sudo). Dugmad:

- „Show script“ / „Hide script“: toggle koji otvara/zatvara skriptu u docked panelu desno od razgovora (`$.ui.open`, id `run-script`, `columns` = pola širine terminala; engine može da ograniči širinu; skrol radi engine, točkić ili strelice dok panel ima fokus). Bash highlighting je u `register.tsx` (komentari zeleni i zatamnjeni, stringovi žuti, promenljive cijan, ključne reči magenta, flagovi plavi). Panel se dokuje samo u fullscreen modu od 110 kolona; na užem terminalu (ili kad se ne može smestiti) „Show script“ otvara skriptu u okviru unutar trake (do 12 linija, ostalo „... N more lines“). Traka je responsive: ispod 60 kolona su kratke oznake (`Run`/`No`/`Show`/`Hide`), a dugmad se prelamaju u novi red. Zatvara se i pri Accept/Decline (atom `open` prati hook `ui.close`). Claude zato ne ispisuje skriptu u odgovoru.
- „Accept“: pokreće skriptu preko `nv-live` (`exec nv-live < skripta`, do 10 minuta): izlaz uživo u prozoru GNOME Terminala „claude terminator“, lozinku za sudo kucaš tamo. Posle izvršenja skripta se briše, a Claude dobija poruku sa exit kodom i izlazom (poslednjih 4000 znakova) i nastavlja sam; kod exit koda 0 poruka se završava podsetnikom da izmenu upiše u beleške po skillu `system-notes`. Dok radi, traka piše „running...“. `run.sh` je zato goli skript (bez poziva `nv-live`); isti fajl radi i kad se pokrene ručno sa `bash $XDG_RUNTIME_DIR/claude-scripts/run-<PID>.sh` ili `nv-claude-sh` (najnoviji `run-*.sh`).
- „Decline“: briše skriptu (bez potvrde) i javlja Claude-u da je odbijena i da je ne pokreće.

Miš (klik i hover) radi samo u fullscreen modu (`/tui fullscreen` ili `CLAUDE_CODE_NO_FLICKER=1`); u običnom modu dugmad i hover ne reaguju. Accept je potvrđen u radu: zenity prozor se otvara i izlaz stiže do Claude-a.

- Fajlovi: `~/.claude/skills/run-preview-mod/` (`.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/register.tsx`, `types/index.d.ts` za stanje `rev` (ponovno iscrtavanje trake posle brisanja skripte), i `busy` (skripta trenutno radi)); Claude Code ga sam učitava iz skills foldera, u svakoj sesiji.
- Radi i u pozadinskim sesijama (potvrđeno 2026-10-14) i u običnom terminalu, uz uslov da je korisnik ispred mašine (prozor terminala). Posle izmene: `/reload-plugins`. Ništa se ne čuva na disku: skripta se briše posle Accept/Decline, a log i exit kod žive samo u privatnom direktorijumu `nv-live` dok se skripta izvršava; izlaz stiže do Claude-a kao poruka (poslednjih 4000 znakova).
- Vraćanje: obrisati `~/.claude/skills/run-preview-mod/`.

## Izlaz uživo za run.sh (`nv-live`)

Izlaz skripte pokrenute običnim izvršavanjem vidi se tek kad se završi. Zato „Accept“ pokreće `run.sh` preko `nv-live` (`~/Documents/ubuntu/bin/nv-live`, opis u `~/Documents/ubuntu/CLAUDE.md`), a `run.sh` je goli skript. Telo radi u maksimizovanom prozoru GNOME Terminala (`--maximize`, naslov uvek „claude terminator“, fiksiran u `nv-live`; podrazumevani profil, spoljašnji shell je interaktivni `bash -ic`, a telo radi neinteraktivno; izlaz uživo, sudo lozinka se kuca tamo), uz upis u `run.log` i `run.rc` u privatnom direktorijumu `$XDG_RUNTIME_DIR/nv-live.XXXXXX` (`mktemp -d`, briše se na izlasku, pa paralelni pozivi iz više sesija ne dele fajlove); na kraju prozor čeka Enter, pa se log i exit kod vraćaju Claude-u. Ako korisnik zatvori prozor pre kraja, `nv-live` to primeti u roku od ~1 s (prati PID unutrašnjeg shella iz `run.pid` u tom direktorijumu) i vraća grešku „terminal window was closed“ sa exit kodom 130.

- Pravilo za Claude-a je u skillu `sudo-run` (vidi odeljak „Blokada sudo-a i skill sudo-run“): jedan goli `run-<PID>.sh` po sesiji (bez omotača), komentar iznad svake linije, a odgovor sadrži samo opis i rečenicu sa `bash $XDG_RUNTIME_DIR/claude-scripts/run-<PID>.sh` (bez `!`); skripta se ne ispisuje, vidi se preko „Show script“.
- Zavisnosti: `gnome-terminal` i otvorena grafička sesija.
- Vraćanje: vratiti u `register.tsx` run-preview moda omotač sa `sudo -A` i `SUDO_ASKPASS` (vidi odeljak askpass) umesto `nv-live`.

## Skill system-notes

Pravila za ove beleške su u globalnom skillu `~/.claude/skills/system-notes-skill/SKILL.md`; u `~/.claude/CLAUDE.md` je samo pokazivač od jednog reda koji traži da se skill učita pre čitanja ili izmene beleški.

- Podsetnici na upis: run-preview mod posle Accept sa exit kodom 0, i skill `sudo-run` (pre skripte koja menja sistem prvo korak „pre“ iz `system-notes`).
- Odluka: MCP server ni hookovi nisu potrebni; beleške su mali Markdown fajlovi u git repou, a indeks su `##` naslovi.
- **Vraćanje:** obrisati `~/.claude/skills/system-notes-skill/` i red „System notes“ iz `~/.claude/CLAUDE.md` (ili pravila iz `SKILL.md` prepisati u `CLAUDE.md`); iz `register.tsx` run-preview moda ukloniti podsetnik uz exit kod 0, a iz `sudo-run` skilla red o `system-notes`.

## Blokada sudo-a i skill sudo-run

Procedura za komande koje korisnik mora sam da pokrene (sudo) je u skillu; u `~/.claude/CLAUDE.md` je samo jedna linija sa pokazivačem, a hook garantuje da se skill koristi.

- **Hook:** `~/.claude/hooks/block-sudo.sh`, registrovan u `~/.claude/settings.json` (`hooks.PreToolUse`, matcher `Bash`). Čita komandu iz JSON-a (`jq`) i blokira (exit 2) svaku u kojoj je `sudo` komanda (na početku linije ili posle `;`, `&`, `|`, `(`, uz opcione `VAR=vrednost` prefikse, pa i `sudo -A`). `echo sudo`, `grep sudo` i `bash run.sh` prolaze. Poruka blokade upućuje Claude-a na skill. Ograničenja: ne hvata `sudo` unutar `bash -c "..."`, a heredoc tela koja sadrže liniju sa `sudo` kao komandom daju lažni pogodak (takve fajlove Claude piše Write alatom, ne preko Bash-a).
- **Skill:** `~/.claude/skills/sudo-run-skill/SKILL.md` (globalni skill) sadrži celu proceduru: `run-<PID>.sh` u `$XDG_RUNTIME_DIR/claude-scripts`, pisanje Write alatom (Bash heredoc sa `sudo` bi hook blokirao), omotač `nv-live`, komentar iznad svake linije, `bash -n` provera i format odgovora na srpskom.
- **Posledica:** permission pravilo za `sudo -A` je obrisano; `sudo` ide samo preko `run.sh` i dugmeta „Accept“.
- **Vraćanje:** obrisati `hooks` ključ iz `~/.claude/settings.json`, `~/.claude/hooks/block-sudo.sh` i `~/.claude/skills/sudo-run-skill/`, pa vratiti proceduru u odeljak „Commands for the user to run“ u `~/.claude/CLAUDE.md`.

## Askpass helper (zenity) za sudo

Helper koji Claude Code-u, koji nema terminal, daje sudo lozinku: `sudo -A` ga pokreće i on otvara `zenity` prozor. Ne koristi se: „Accept“ ide preko `nv-live` (lozinka se kuca u terminalu), `block-sudo` hook blokira `sudo` iz Bash alata, a permission pravilo za `sudo -A` je obrisano.

- Helper je ostao: `~/.local/bin/sudo-askpass` (`chmod 700`, `exec zenity --password`). Ručni poziv: `SUDO_ASKPASS=$HOME/.local/bin/sudo-askpass sudo -A <komanda>`.
- Vraćanje na stari način: vidi „run-preview mod“ (omotač u `register.tsx`) i vratiti pravilo `Bash(SUDO_ASKPASS=* sudo -A *)` preko `/permissions`, uz izuzimanje iz `block-sudo` hooka.
- Brisanje: obrisati `~/.local/bin/sudo-askpass`.

## Isključeni claude.ai konektori

Svi claude.ai konektori (Claude Docs, Cloudflare, Epidemic Sound, Gmail, Calendar, Drive, HubSpot, Slack) su isključeni jer se ne koriste; svaki je trošio kontekst na `authenticate` stubove i instrukcije (oko 7k tokena po sesiji).

- Podešavanje: `env.ENABLE_CLAUDEAI_MCP_SERVERS = "false"` u `~/.claude/settings.json`; važi od sledećeg starta sesije.
- Vraćanje: obrisati taj ključ iz `env` (ili vratiti `~/.claude/backups/settings.json.pre-no-connectors`). Pojedinačno se konektori i dalje mogu uključiti u `/mcp` samo ako je varijabla uklonjena.

## health-bars mod (limiti i context kao health bar)

Jedan red iznad prompta sa dve trake jedna pored druge: **limiti** (`SESSION` 5h prozor i `WEEKLY` 7d prozor u jednoj traci) i `CONTEXT` (popunjenost context prozora). Responsive: iz širine terminala (`e.viewport.columns`) bira se prvi od koraka koji staje: pun prikaz → bez odbrojavanja (tokeni ostaju) → traka od 8 blokova → 6 bez labela (SESSION/WEEKLY postaju `S`/`W`) → bez modela/effort-a (tek tada) → traka od 4 (ako ni to ne staje, prelama se u novi red bez razmaka među redovima). Svaka traka ima 12 blokova, pokazuje šta je ostalo (prazni se kako trošiš limit) i procenat preostalog. Redosled u traci CONTEXT: labela, brojevi (procenat, popunjenost/veličina), pa graf, pa zatamnjeno model i effort.

- **Traka limita:** svaka ćelija je polu-blok `▀`: **gornja polovina je SESSION** (boja teksta, crvena), **donja WEEKLY** (boja pozadine, žuta); prazna polovina je tamno siva (`EMPTY`, `#3f3f46`). Raspored u redu: `SESSION 70% 3h 0m ▀▀▀▀▀▀▀▀▀▀▀▀ WEEKLY 75% 2d 1h` (SESSION tekst levo od trake, WEEKLY desno; labela u boji svog prozora, procenat, zatamnjeno vreme do reseta). Ako postoji samo jedan prozor, druga polovina je prazna i bez njenog teksta; bez oba prozora traka limita se ne crta.
- **Boje** su fiksne (hex, ne tema): SESSION crvena, WEEKLY žuta; CONTEXT je podeljen na trećine (po 4 bloka: crveno, žuto, zeleno, sleva udesno; prazni se zdesna, pa crveno ostaje poslednje). Prazni deo trake je zatamnjen.
- **SESSION i WEEKLY** pokazuju i vreme do reseta. Ne crtaju se dok nema podataka (van pretplate ili pre prvog odgovora). Posle `/clear` i novog starta ostaju poslednje poznate vrednosti (čuvaju se u `$.store` pod ključem `limits`, jer se atom session stanja prazni na `/clear`); prozor čije je vreme reseta prošlo crta se kao nepotrošen.
- **CONTEXT** je uvek tu. Pored procenta stoji popunjenost i veličina prozora (npr. `71k/1M`; bez čitanja `0k/1M`), u svakom koraku responsivnosti (nikad se ne skida), pa zatamnjeno model i effort (npr. `sonnet-5-5 · high`). Model se čita pri svakom iscrtavanju (prati `/model`). Effort se beleži iz poslednjeg zahteva glavne petlje (`turn.step`, bez subagenata; korak bez effort-a ništa ne menja) i čuva u `$.store` pod ključem `effort` zajedno sa modelom, pa ostaje posle `/clear` ili starta; važi samo dok je model isti, a nema ga za model bez effort-a ili dok ništa nije zabeleženo. Dok nema podatka (nova sesija, posle `/compact`) traka pokazuje 100%.
- **Podaci:** `session.measure` hook (`rateLimits`, `context.percent`), početno stanje iz `$.session.usage()` pri `session.start`.
- **Podsetnici:** skroz desno u istom redu je `⏰ N`, broj podsetnika iz liste u `~/.claude/reminders.md` (sekcija „## Reminder list“; ne nalazi se u `CLAUDE.md`, nema SessionStart hooka, podsetnici se prikazuju samo ovde; čita se pri svakom iscrtavanju). Klik na broj (toggle) otvara/zatvara celu listu iznad reda, poravnatu udesno. Ispred svakog podsetnika je dugme „✕“: klik ga briše iz `~/.claude/reminders.md` (fajl se pri kliku ponovo čita) i prikazuje toast; kad se obriše poslednji, upisuje se `- (empty)`. Klik radi samo u fullscreen modu.
- **Agent za podsetnik:** pored „✕“ je dugme „▶“. Klik pokreće pozadinsku sesiju (`claude --bg --name "rem: <tekst>" "<tekst podsetnika>"`, vidi se u Agent view-u) i pamti vezu podsetnik → id sesije u `$.store` pod ključem `reminderAgents` (preživljava restart). Posle toga dugme pokazuje stanje sesije kao Agent view: spinner dok radi, `✓` završena, `✗` pala, `●` ostalo (npr. čeka unos), `○` još nepoznato; kad sesije više nema (`claude rm`), opet „▶“ (klik pravi novog agenta). Klik na dugme sa stanjem samo prikazuje toast sa stanjem i prvim redom poslednjeg odgovora (iz transkripta `~/.claude/projects/<cwd>/<sessionId>.jsonl`); ništa se ne otvara ni kopira. Stanja se čitaju sa `claude agents --json --all` na 3 s, ali samo dok je lista podsetnika otvorena ili neka sesija radi (i jednom pri otvaranju liste); spinner se pomera na 120 ms samo dok lista stoji otvorena i sesija radi. Plugin ne može da prebaci ekran u drugu sesiju, pa se u nju ulazi preko `claude attach <id>` ili ← (Agent view). `claude --bg` radi samo u poverenom folderu: pokreće se u folderu sesije, a ako nije poveren, u `~/Documents`.
- **Panel podsetnika (⏰):** ima isti blagi okvir kao hover panel run-preview moda (`borderStyle="round"` + `borderDimColor`).
- **Fajlovi:** `~/.claude/skills/health-bars-mod/` (`.claude-plugin/plugin.json`, `hooks/register.tsx`, `types/index.d.ts`, `tests/band.test.ts`); Claude Code ga sam učitava iz skills foldera, u svakoj sesiji. Testovi: `claude plugin test <folder>`; posle izmene: `/reload-plugins`.
- **Vraćanje:** obrisati `~/.claude/skills/health-bars-mod/`. Za staru lokaciju podsetnika (u `CLAUDE.md`): vratiti `~/.claude/backups/CLAUDE.md.pre-reminders-file` i `register.{tsx,js}`/`band.test.ts` sa istim sufiksom `.pre-reminders-file` u `backups/`.

## Prečica za skrivanje trake iznad prompta (keybindings)

`~/.claude/keybindings.json` vezuje `ctrl+x a` (kontekst `Chat`) na akciju `abovePrompt:toggle`, pa skriva/prikazuje health-bars traku. Podrazumevana `ctrl+x ctrl+a` i dalje radi. Jednotasterska `ctrl+b` je probana, ali se traka tada ne iscrtava dok se ne počne kucati (chord prečice rade ispravno), pa je zamenjena chordom.

- Vraćanje: obrisati `~/.claude/keybindings.json`.

## Skill remind

Globalni skill `~/.claude/skills/remind-skill/SKILL.md` (ime `remind`) dodaje, briše i prikazuje podsetnike u `~/.claude/reminders.md` (format: sekcija `## Reminder list`, jedna `- ` stavka po redu, `- (empty)` kad je lista prazna). Isti fajl čita health-bars mod za `⏰ N`.

- Vraćanje: obrisati `~/.claude/skills/remind-skill/`.

## Skill brainstorm

Globalni skill `~/.claude/skills/brainstorm-skill/SKILL.md` (ime `brainstorm`) pokreće se samo ručno, `/brainstorm <slobodan tekst>` (`disable-model-invocation: true`). Ne izvodi brainstorm, nego definiše zadatak i ispisuje uglačan prompt (na engleskom, u jednom code bloku) za novu Claude Code sesiju: lead + podagenti kao stručni tim po temi, diverge pa converge, izlaz na srpskom (latinica). Uz prompt predlaže model i effort sa komandom `claude --model ... --effort ...`.

- Vraćanje: obrisati `~/.claude/skills/brainstorm-skill/`.
