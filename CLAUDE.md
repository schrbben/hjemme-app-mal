# Hjemme-appen: teknisk oversikt for Claude

Appen er laget for mobil, og hele brukerflaten er på norsk bokmål. Den har tre deler med en felles appvelger øverst: **Fryser**, **Bod** og **Rydding**. Oppsett for en ny bruker står i README.md (delen «Til Claude»).

## Teknologi
- **Rammeverk:** Next.js 14.1 (App Router), React 18, TypeScript og Tailwind 3.4. Alle sider er `'use client'`.
- **Database:** Supabase via `@supabase/supabase-js` 2.39 med den offentlige anon-nøkkelen.
  - Det er **ingen innlogging**. Tilgangsreglene (RLS) lar `anon` lese og skrive alt. Det er et bevisst valg.
  - Sanntid via `postgres_changes`, så endringer vises på alle telefoner.
- **3D i boden:** three 0.172, @react-three/fiber 8.18 og camera-controls 3.1.2.
  - Kameraet styres med `CameraControlsImpl.install({ THREE })`.
  - Lerretet bruker `frameloop="demand"` og tegner bare på nytt ved `invalidate()`.
- **Varsler:** web push med `web-push` 3.6.7 og VAPID-nøkler. Service workeren ligger i `public/sw.js`.
- **Drift:** Vercel (Hobby) legger ut automatisk ved push til `main`. Supabase er på gratisplanen.

## Struktur
| Sti | Innhold |
| --- | --- |
| `app/page.tsx` | Fryseren (rad i `rooms` med `slug = 'felles'`) |
| `app/[slug]/page.tsx` | Andre frysere, én per slug |
| `app/bod/page.tsx` | Boden: lasting, sanntid, redigering, flytting og stabling |
| `app/rydding/page.tsx` | Rydding: forslag, gjort/angre, ark og innstillinger |
| `app/api/keepalive` | Daglig Vercel-cron (`vercel.json`), så Supabase ikke pauses |
| `app/api/rydding/varsel` | Morgenvarselet. Tåler å kalles ofte, se under. `?dryRun` viser teksten uten å sende |
| `app/api/rydding/varsel/test` | POST `{endpoint}` sender et testvarsel til én telefon |
| `components/AppSwitcher.tsx` | Fryser / Bod / Rydding |
| `components/bod/*` | `StorageScene` (3D), `BoxSheet`, `ContainerDialog`, `EditPanel`, `ShelfMap` |
| `components/rydding/*` | Rader og ark (Sheet), innstillinger og varsler |
| `lib/storage.ts` | Modell og regler for boden: rom, hyller, plasser, mål og stabling |
| `lib/rydding.ts` | Regler for rydding: frist, farge, hastegrad, forslag, spredning og handleliste |
| `lib/bodSeed.json`, `lib/ryddingSeed.json` | Eksempeldata (`?demo`) og startoppgaver |
| `supabase/oppsett.sql` | Hele databasen, kan kjøres flere ganger |
| `supabase/varsel.sql` | pg_net og pg_cron, som vekker varselsiden hvert kvarter |

## Datamodell
- **Fryser:**
  - `rooms` er frysere, og forsiden bruker slug `felles`.
  - `items` er varene, med `status` lik `active` eller `archived`.
  - `history` er historikken.
- **Bod:**
  - `storage_boxes`:
    - Typer (`kind`): `box`, `bin`, `suitcase`, `cardboard` eller `loose`.
    - Størrelse (`size`): `normal`, `low` eller `long`.
    - Plassering (`placement`): `shelf` (med `shelf`, `level` 1–4, der 4 er oppå hylla, og `slot` 1–4), `floor` (med `pos_x`, `pos_z` og `rotation`), `stacked` (med `stack_on`) eller `elsewhere` (med `location`).
    - Rommet (`room`) er `kjeller` eller `loft`.
  - `storage_items` er innholdet, med `box_id`.
  - Kofferter og lange bokser tar to plasser (`spanOf`). Lave ting kan stå oppå hylla (nivå 4).
- **Rydding:**
  - Tabellene heter `chore_*`, fordi `rooms` er tatt av fryseren: `chore_rooms`, `chores`, `chore_completions` (ett «gjort» per oppgave per dag, datoer i norsk tid) og `chore_settings` (én rad).
  - Frist, farge og forslag regnes ut i appen, ikke i databasen.
  - `chore_settings` har ryddedag (0 = søndag), tak i minutter, varseltid, «tid i dag» (`cap_today` og `cap_today_on`) og `notify_sent_on`.
- **Varsler:** `push_subscriptions` har én rad per telefon.

## Regler i Rydding som avviker bevisst fra en enkel modell
Reglene er testet med simulering over to år.
- **Hastegrad:** (dager siden sist ÷ intervall) × vekt, pluss et tillegg for hvor langt oppgaven har kommet mot rødgrensen. Uten tillegget blir lange, sjeldne oppgaver aldri tatt før de er røde.
- **Røde oppgaver** tas alltid med i forslaget, også over tiden.
- **Fylling av tid:** er det tid igjen, fylles den med det som forfaller innen neste ryddedag, med nærmeste frist først. Oppgaver som ble gjort for under et halvt intervall siden, tas ikke tidlig.
- **Faste måneder:** fristen blir neste faste måned, men minst et halvt intervall etter siste gang.
- **Spredning:** oppgaver som aldri er gjort, får startfrist (`initial_due`) spredt utover ukene.
- **Handlelista** viser varer til oppgaver som forfaller innen 7 dager, eller som er med i forslaget. «Kjøpt» betyr at `purchase_done_for` er lik eller senere enn fristen.

## Morgenvarselet
- **Kallet:** Supabase-jobben `rydding-varsel` (pg_cron og pg_net) kaller `/api/rydding/varsel` hvert kvarter.
- **Når det sendes:** ruten sender bare på ryddedagen, etter `notify_time` (norsk tid), og én gang per dag. Dagen reserveres med `notify_sent_on`, og frigis igjen hvis ingenting kom fram.
- **Hvorfor Supabase:** Vercel Hobby-cron er for grov, og kall fra Supabase slipper gjennom Vercels robotsperre.
- **Nøkler:** `NEXT_PUBLIC_VAPID_PUBLIC_KEY` og `VAPID_PRIVATE_KEY` ligger i Vercel og i `.env.local`. Avsender (subject) er appens adresse, hentet fra `VERCEL_PROJECT_PRODUCTION_URL`, og Apple godtar det.
- **iPhone:** varsler virker bare når appen er lagt på Hjem-skjermen (iOS 16.4+). Tillatelsen må bes om direkte fra et trykk.

## Slik jobber du i prosjektet
- **Test lokalt** med `npm run dev`.
  - `/bod?demo` og `/rydding?demo` bruker eksempeldata og skriver ingenting til databasen. Bruk dem, så du ikke roter til ekte data.
  - Test oppsett på mobilbredde (375 px).
- **Sanntid:** React StrictMode i utviklingsmodus ødelegger sanntidskoblingen. Test sanntid med `npm run build && npm start`.
- **Varsler:** den innebygde nettleseren i Claude-appen kan ikke registrere service workers eller gi varsler. Ekte varsler må testes på telefonen.
- **Databaseendringer:**
  - Lag en ny nummerert fil i `supabase/`, og kjør den med Supabase-koblingen (`apply_migration`).
  - Sjekk resultatet etterpå, og kjør `get_advisors`.
  - Vil du teste SQL uten risiko, kjør den i en transaksjon i et eget testskjema, og avslutt med en bevisst feil (`raise exception`), så alt rulles tilbake.
- **Hemmeligheter:** skriv aldri ut nøkler i chatten. Den private varselnøkkelen legges inn i Vercel av brukeren selv.
- **Produksjon:** curl mot `*.vercel.app` blir ofte stoppet av Vercels robotsperre. Sjekk heller i nettleseren, eller kall fra Supabase med `net.http_get`.
- **Ved hver push:**
  - Spør før du pusher, fordi en push til `main` legges ut med en gang.
  - Skriv commit-meldinger på norsk.
- **Brukerønsker som har fungert godt:**
  - Oversikt framfor realisme i 3D, med kameraet utenfor rommet som i et dukkehus.
  - Paneler som ikke dekker scenen.
  - Flytting bare etter at man har trykket «Flytt».
  - Angre i stedet for spørsmålet «Er du sikker?».

## Kjente forbedringer
- **Ikoner:** appen mangler ikoner. `public/manifest.json` og `app/layout.tsx` peker på `icon-192.png` og `icon-512.png`, som ikke finnes. Lag dem gjerne, så ikonet på hjemskjermen blir pent.
- **Next.js 14.1** har kjente sårbarheter (`npm audit`). Oppgrader til nyeste 14.2.x, og test etterpå.
- **Rom i boden:** bodens rom (`kjeller`/`loft`) og hyller er laget for originalens boder. Tilpass `ROOMS` i `lib/storage.ts`, `SHELF_LAYOUT` i `StorageScene.tsx` og sjekken på `room` i databasen hvis brukeren har andre rom.
