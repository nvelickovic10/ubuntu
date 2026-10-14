# Claude Code

Naše izmene Claude Code-a (hookovi, modovi, permission pravila, helperi), svaka u svom `##` odeljku; samo konačno stanje.

## run-preview mod (traka iznad prompta)

Traka „run.sh ready“ iznad prompta za `$XDG_RUNTIME_DIR/run.sh`, skriptu koju Claude piše kad korisnik treba nešto da pokrene (sudo). Dugmad:

- „Show script“ / „Hide script“: toggle koji otvara/zatvara skriptu u docked panelu desno od razgovora (`$.ui.open`, id `run-script`, `columns` = pola širine terminala; engine može da ograniči širinu; skrol radi engine, točkić ili strelice dok panel ima fokus). Bash highlighting je u `register.tsx` (komentari zeleni i zatamnjeni, stringovi žuti, promenljive cijan, ključne reči magenta, flagovi plavi). Panel se dokuje samo u fullscreen modu od 110 kolona; na užem terminalu (ili kad se ne može smestiti) „Show script“ otvara skriptu u okviru unutar trake (do 12 linija, ostalo „... N more lines“). Traka je responsive: ispod 60 kolona su kratke oznake (`Run`/`No`/`Show`/`Hide`), a dugmad se prelamaju u novi red. Zatvara se i pri Accept/Decline (atom `open` prati hook `ui.close`). Claude zato ne ispisuje skriptu u odgovoru.
- „Accept“: pokreće skriptu preko `nv-live` (`exec nv-live < run.sh`, do 10 minuta): izlaz uživo u prozoru GNOME Terminala „claude terminator“, lozinku za sudo kucaš tamo. Posle izvršenja skripta se briše, a Claude dobija poruku sa exit kodom i izlazom (poslednjih 4000 znakova) i nastavlja sam. Dok radi, traka piše „running...“. `run.sh` je zato goli skript (bez poziva `nv-live`); isti fajl radi i kad se pokrene ručno sa `bash $XDG_RUNTIME_DIR/run.sh`.
- „Decline“: briše skriptu (bez potvrde) i javlja Claude-u da je odbijena i da je ne pokreće.

Miš (klik i hover) radi samo u fullscreen modu (`/tui fullscreen` ili `CLAUDE_CODE_NO_FLICKER=1`); u običnom modu dugmad i hover ne reaguju. Accept je potvrđen u radu: zenity prozor se otvara i izlaz stiže do Claude-a.

- Fajlovi: `~/.claude/skills/run-preview/` (`.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/register.tsx`, `types/index.d.ts` za stanje `rev` (ponovno iscrtavanje trake posle brisanja skripte), i `busy` (skripta trenutno radi)); Claude Code ga sam učitava iz skills foldera, u svakoj sesiji.
- Radi samo u interaktivnom terminalu (u pozadinskim sesijama se traka ne iscrtava) i kad je korisnik ispred mašine (zenity prozor). Posle izmene: `/reload-plugins`.
- Vraćanje: obrisati `~/.claude/skills/run-preview/`.

## Izlaz uživo za run.sh (`nv-live`)

Izlaz skripte pokrenute običnim izvršavanjem vidi se tek kad se završi. Zato „Accept“ pokreće `run.sh` preko `nv-live` (`~/Documents/ubuntu/bin/nv-live`, opis u `~/Documents/ubuntu/CLAUDE.md`), a `run.sh` je goli skript. Telo radi u maksimizovanom prozoru GNOME Terminala (`--maximize`, naslov uvek „claude terminator“, fiksiran u `nv-live`; podrazumevani profil, spoljašnji shell je interaktivni `bash -ic`, a telo radi neinteraktivno; izlaz uživo, sudo lozinka se kuca tamo), uz upis u `$XDG_RUNTIME_DIR/run.log` i `run.rc`; na kraju prozor čeka Enter, pa se log i exit kod vraćaju Claude-u. Ako korisnik zatvori prozor pre kraja, `nv-live` to primeti u roku od ~1 s (prati PID unutrašnjeg shella iz `run.pid`) i vraća grešku „terminal window was closed“ sa exit kodom 130.

- Pravilo za Claude-a je u skillu `sudo-run` (vidi odeljak „Blokada sudo-a i skill sudo-run“): jedan goli `run.sh` (bez omotača), komentar iznad svake linije, a odgovor sadrži samo opis i rečenicu sa `bash $XDG_RUNTIME_DIR/run.sh` (bez `!`); skripta se ne ispisuje, vidi se preko „Show script“.
- Zavisnosti: `gnome-terminal` i otvorena grafička sesija.
- Vraćanje: vratiti u `register.tsx` run-preview moda omotač sa `sudo -A` i `SUDO_ASKPASS` (vidi odeljak askpass) umesto `nv-live`.

## Blokada sudo-a i skill sudo-run

Procedura za komande koje korisnik mora sam da pokrene (sudo) više nije u `~/.claude/CLAUDE.md` (tamo je samo jedna linija sa pokazivačem), nego u skillu; hook garantuje da se skill koristi.

- **Hook:** `~/.claude/hooks/block-sudo.sh`, registrovan u `~/.claude/settings.json` (`hooks.PreToolUse`, matcher `Bash`). Čita komandu iz JSON-a (`jq`) i blokira (exit 2) svaku u kojoj je `sudo` komanda (na početku linije ili posle `;`, `&`, `|`, `(`, uz opcione `VAR=vrednost` prefikse, pa i `sudo -A`). `echo sudo`, `grep sudo` i `bash run.sh` prolaze. Poruka blokade upućuje Claude-a na skill. Ograničenja: ne hvata `sudo` unutar `bash -c "..."`, a heredoc tela koja sadrže liniju sa `sudo` kao komandom daju lažni pogodak (takve fajlove Claude piše Write alatom, ne preko Bash-a).
- **Skill:** `~/.claude/skills/sudo-run/SKILL.md` (globalni skill) sadrži celu proceduru: `run.sh` u `$XDG_RUNTIME_DIR`, pisanje Write alatom (Bash heredoc sa `sudo` bi hook blokirao), omotač `nv-live`, komentar iznad svake linije, `bash -n` provera i format odgovora na srpskom.
- **Posledica:** permission pravilo za `sudo -A` je obrisano; `sudo` ide samo preko `run.sh` i dugmeta „Accept“.
- **Vraćanje:** obrisati `hooks` ključ iz `~/.claude/settings.json`, `~/.claude/hooks/block-sudo.sh` i `~/.claude/skills/sudo-run/`, pa vratiti proceduru u odeljak „Commands for the user to run“ u `~/.claude/CLAUDE.md`.

## Askpass helper (zenity) za sudo

Nekadašnji način da Claude Code, koji nema terminal, dobije sudo lozinku: `sudo -A` pokreće helper koji otvara `zenity` prozor. Više se ne koristi: „Accept“ ide preko `nv-live` (lozinka se kuca u terminalu), `block-sudo` hook blokira `sudo` iz Bash alata, a permission pravilo za `sudo -A` je obrisano.

- Helper je ostao: `~/.local/bin/sudo-askpass` (`chmod 700`, `exec zenity --password`). Ručni poziv: `SUDO_ASKPASS=$HOME/.local/bin/sudo-askpass sudo -A <komanda>`.
- Vraćanje na stari način: vidi „run-preview mod“ (omotač u `register.tsx`) i vratiti pravilo `Bash(SUDO_ASKPASS=* sudo -A *)` preko `/permissions`, uz izuzimanje iz `block-sudo` hooka.
- Brisanje: obrisati `~/.local/bin/sudo-askpass`.

## Isključeni claude.ai konektori

Svi claude.ai konektori (Claude Docs, Cloudflare, Epidemic Sound, Gmail, Calendar, Drive, HubSpot, Slack) su isključeni jer se ne koriste; svaki je trošio kontekst na `authenticate` stubove i instrukcije (oko 7k tokena po sesiji).

- Podešavanje: `env.ENABLE_CLAUDEAI_MCP_SERVERS = "false"` u `~/.claude/settings.json`; važi od sledećeg starta sesije.
- Vraćanje: obrisati taj ključ iz `env` (ili vratiti `~/.claude/backups/settings.json.pre-no-connectors`). Pojedinačno se konektori i dalje mogu uključiti u `/mcp` samo ako je varijabla uklonjena.

## health-bars mod (limiti i context kao health bar)

Jedan red iznad prompta sa dve trake jedna pored druge: **limiti** (`SESSION` 5h prozor i `WEEKLY` 7d prozor u jednoj traci) i `CONTEXT` (popunjenost context prozora). Responsive: iz širine terminala (`e.viewport.columns`) bira se prvi od koraka koji staje: pun prikaz → bez tokena i odbrojavanja → traka od 8 blokova → 6 bez labela (SESSION/WEEKLY postaju `S`/`W`) → bez modela/effort-a (tek tada) → traka od 4 (ako ni to ne staje, prelama se u novi red bez razmaka među redovima). Svaka traka ima 12 blokova, pokazuje šta je ostalo (prazni se kako trošiš limit) i procenat preostalog.

- **Traka limita:** svaka ćelija je polu-blok `▀`: **gornja polovina je SESSION** (boja teksta, crvena), **donja WEEKLY** (boja pozadine, žuta); prazna polovina je tamno siva (`EMPTY`, `#3f3f46`). Raspored u redu: `SESSION 70% 3h 0m ▀▀▀▀▀▀▀▀▀▀▀▀ WEEKLY 75% 2d 1h` (SESSION tekst levo od trake, WEEKLY desno; labela u boji svog prozora, procenat, zatamnjeno vreme do reseta). Ako postoji samo jedan prozor, druga polovina je prazna i bez njenog teksta; bez oba prozora traka limita se ne crta.
- **Boje** su fiksne (hex, ne tema): SESSION crvena, WEEKLY žuta; CONTEXT je podeljen na trećine (po 4 bloka: crveno, žuto, zeleno, sleva udesno; prazni se zdesna, pa crveno ostaje poslednje). Prazni deo trake je zatamnjen.
- **SESSION i WEEKLY** pokazuju i vreme do reseta. Ne crtaju se dok nema podataka (van pretplate ili pre prvog odgovora). Posle `/clear` i novog starta ostaju poslednje poznate vrednosti (čuvaju se u `$.store` pod ključem `limits`, jer se atom session stanja prazni na `/clear`); prozor čije je vreme reseta prošlo crta se kao nepotrošen.
- **CONTEXT** je uvek tu. Pored procenta stoji popunjenost i veličina prozora (npr. `71k/1M`; bez čitanja `0k/1M`), pa zatamnjeno model i effort (npr. `sonnet-5-5 · high`). Model se čita pri svakom iscrtavanju (prati `/model`). Effort se beleži iz poslednjeg zahteva glavne petlje (`turn.step`, bez subagenata; korak bez effort-a ništa ne menja) i čuva u `$.store` pod ključem `effort` zajedno sa modelom, pa ostaje posle `/clear` ili starta; važi samo dok je model isti, a nema ga za model bez effort-a ili dok ništa nije zabeleženo. Dok nema podatka (nova sesija, posle `/compact`) traka pokazuje 100%.
- **Podaci:** `session.measure` hook (`rateLimits`, `context.percent`), početno stanje iz `$.session.usage()` pri `session.start`.
- **Podsetnici:** skroz desno u istom redu je `⏰ N`, broj podsetnika iz liste u `~/.claude/CLAUDE.md` (sekcija „Reminder list“, nema više SessionStart hooka, podsetnici se prikazuju samo ovde; čita se pri svakom iscrtavanju). Klik na broj (toggle) otvara/zatvara celu listu iznad reda, poravnatu udesno. Ispred svakog podsetnika je dugme „✕“: klik ga briše iz `~/.claude/CLAUDE.md` (fajl se pri kliku ponovo čita) i prikazuje toast; kad se obriše poslednji, upisuje se `- (empty)`. Klik radi samo u fullscreen modu.
- **Agent za podsetnik:** pored „✕“ je dugme „▶“. Klik pokreće pozadinsku sesiju (`claude --bg --name "rem: <tekst>" "<tekst podsetnika>"`, vidi se u Agent view-u) i pamti vezu podsetnik → id sesije u `$.store` pod ključem `reminderAgents` (preživljava restart). Posle toga dugme pokazuje stanje sesije kao Agent view: spinner dok radi, `✓` završena, `✗` pala, `●` ostalo (npr. čeka unos), `○` još nepoznato; kad sesije više nema (`claude rm`), opet „▶“ (klik pravi novog agenta). Klik na dugme sa stanjem samo prikazuje toast sa stanjem i prvim redom poslednjeg odgovora (iz transkripta `~/.claude/projects/<cwd>/<sessionId>.jsonl`); ništa se ne otvara ni kopira. Stanja se čitaju sa `claude agents --json --all` na 3 s, ali samo dok je lista podsetnika otvorena ili neka sesija radi (i jednom pri otvaranju liste); spinner se pomera na 120 ms samo dok lista stoji otvorena i sesija radi. Plugin ne može da prebaci ekran u drugu sesiju, pa se u nju ulazi preko `claude attach <id>` ili ← (Agent view). `claude --bg` radi samo u poverenom folderu: pokreće se u folderu sesije, a ako nije poveren, u `~/Documents`.
- **Panel podsetnika (⏰):** ima isti blagi okvir kao hover panel run-preview moda (`borderStyle="round"` + `borderDimColor`).
- **Fajlovi:** `~/.claude/skills/health-bars/` (`.claude-plugin/plugin.json`, `hooks/register.tsx`, `types/index.d.ts`, `tests/band.test.ts`); Claude Code ga sam učitava iz skills foldera, u svakoj sesiji. Testovi: `claude plugin test <folder>`; posle izmene: `/reload-plugins`.
- **Vraćanje:** obrisati `~/.claude/skills/health-bars/`.

## Prečica za skrivanje trake iznad prompta (keybindings)

`~/.claude/keybindings.json` vezuje `ctrl+x a` (kontekst `Chat`) na akciju `abovePrompt:toggle`, pa skriva/prikazuje health-bars traku. Podrazumevana `ctrl+x ctrl+a` i dalje radi. Jednotasterska `ctrl+b` je probana, ali se traka tada ne iscrtava dok se ne počne kucati (chord prečice rade ispravno), pa je zamenjena chordom.

- Vraćanje: obrisati `~/.claude/keybindings.json`.
