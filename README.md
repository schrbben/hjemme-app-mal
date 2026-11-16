# Hjemme: fryser, bod og rydding

En app til mobilen med tre deler:

- **Fryser:** hva som ligger i fryseren, og hvor lenge det har ligget der.
- **Bod:** boden din i 3D. Trykk på en boks for å se hva som er i den, og legg til eller ta ut ting.
- **Rydding:** faste oppgaver hjemme. Appen foreslår hva som bør gjøres på ryddedagen, og sender et varsel om morgenen.

Dette er en kopi av en app som er i bruk, med eksempeldata i stedet for ekte ting. Du lager din egen kopi, og Claude hjelper deg å tilpasse den, for eksempel til målene på din bod.

---

## Dette trenger du

| Konto | Hva den brukes til | Pris |
| --- | --- | --- |
| **Claude Pro** | Claude bygger, setter opp og endrer appen for deg | ca. 200–250 kr i måneden |
| **GitHub** | Lagrer koden til appen | Gratis |
| **Supabase** | Databasen, altså det du legger inn i appen | Gratis |
| **Vercel** | Legger appen ut på nettet, så du kan åpne den på mobilen | Gratis |

**Om Claude Pro:** gratisversjonen av Claude kan ikke bygge og legge ut apper, så du trenger Pro mens du setter opp og endrer appen. Du kan si opp abonnementet når appen er slik du vil ha den. Appen fortsetter å virke, fordi den ligger på dine egne gratiskontoer. Ønsker du endringer senere, kan du ta Pro igjen for en måned.

---

## Steg for steg

Det meste gjør du bare én gang. Regn med rundt halvannen time totalt, og av det er ca. en time sammen med Claude.

| # | Steg | Tid |
| --- | --- | --- |
| 1 | Claude Pro og Claude-appen | 10 min |
| 2 | GitHub-konto | 5 min |
| 3 | Supabase-konto og database | 10 min |
| 4 | Din egen kopi av appen på nettet | 5 min |
| 5 | Koble Claude til Supabase og Vercel | 5 min |
| 6 | La Claude sette opp resten | 30–60 min |
| 7 | Legg appen på mobilen | 5 min |

### 1. Claude Pro og Claude-appen (10 min)
1. Gå til [claude.ai](https://claude.ai), lag en konto og velg **Pro**.
2. Last ned **Claude-appen** til datamaskinen fra [claude.com/download](https://claude.com/download), og logg inn.

### 2. GitHub-konto (5 min)
1. Lag en konto på [github.com/signup](https://github.com/signup).
2. Skriv ned brukernavnet ditt. Claude trenger det senere.

### 3. Supabase-konto og database (10 min)
1. Gå til [supabase.com](https://supabase.com), trykk **Start your project** og velg **Continue with GitHub**.
2. Trykk **New project**, og fyll inn:
   - **Name:** `hjemme`
   - **Database Password:** trykk **Generate a password**, og ta vare på passordet, for eksempel i passordappen din.
   - **Region:** *North EU (Stockholm)*
3. Trykk **Create new project**, og vent et par minutter til prosjektet er klart.

### 4. Din egen kopi av appen på nettet (5 min)
1. Trykk på knappen under:

   [![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fschrbben%2Fhjemme-app-mal&repository-name=hjemme-app&project-name=hjemme-app)

2. Velg **Continue with GitHub**. Da lages Vercel-kontoen din. Velg gratisplanen **Hobby** hvis du blir spurt.
3. Behold navnet `hjemme-app`, huk av **Create private repository**, og trykk **Create**.
4. Vent 2–3 minutter. Nå har du din egen kopi av koden på GitHub, og appen ligger på nettet med en adresse som `hjemme-app-….vercel.app`.

Appen viser feilmeldinger helt til databasen er koblet til i steg 6. Det er helt normalt.

### 5. Koble Claude til Supabase og Vercel (5 min)
1. Åpne Claude-appen, og gå til **Innstillinger → Connectors** (Koblinger).
2. Finn **Supabase**, trykk **Connect** og logg inn.
3. Gjør det samme for **Vercel**.

Da kan Claude sette opp databasen og innstillingene for deg, så du slipper å kopiere nøkler.

### 6. La Claude sette opp resten (30–60 min)
1. I Claude-appen velger du fanen **Code**, og så en mappe på datamaskinen, for eksempel *Dokumenter*.
2. Lim inn denne meldingen, og fyll inn GitHub-brukernavnet ditt:

   > Hei! Jeg vil sette opp Hjemme-appen min. Les https://github.com/schrbben/hjemme-app-mal/blob/main/README.md og følg delen «Til Claude». GitHub-brukernavnet mitt er: ______

3. Claude gjør jobben og ber deg om hjelp underveis. Den kan for eksempel be deg logge inn på GitHub i nettleseren, lime inn en nøkkel i Vercel eller svare på spørsmål om boden din.

### 7. Legg appen på mobilen (5 min)
1. Åpne adressen til appen i **Safari** på iPhone, eller Chrome på Android.
2. Trykk **Del → Legg til på Hjem-skjerm**. Nå ligger appen på mobilen som en vanlig app.
3. Åpne den fra ikonet, gå til **Rydding → ⚙️** og trykk **Slå på varsler**. Varsler virker bare når appen åpnes fra ikonet på hjemskjermen.

Vil flere bruke appen, sender du dem adressen, og de gjør steg 7.

---

## Til Claude

*Denne delen er til Claude. Eili trenger ikke lese den.*

Du hjelper Eili å sette opp og tilpasse sin egen kopi av denne appen. Regn med at hun ikke er teknisk.

- Snakk norsk bokmål og enkelt, og ta ett steg om gangen.
- Når hun må gjøre noe selv, si nøyaktig hva hun skal trykke på, og hvorfor.
- Spør før du installerer noe på maskinen hennes.
- Hvis tidsestimatene i stegene over ikke stemmer for henne, si fra underveis.
- I repoet hennes ligger **CLAUDE.md** med arkitektur, regler og fallgruver. Les den før du endrer kode.

### A. Oppsett, i denne rekkefølgen

1. **Koden.** Vercel-knappen i steg 4 laget et privat repo på GitHub-kontoen hennes, sannsynligvis `<brukernavn>/hjemme-app`. Klon det til mappen hun valgte.
   - Mangler Git, spør først og installer det: `winget install Git.Git` på Windows, `xcode-select --install` på Mac.
   - For å kunne pushe må hun logge inn på GitHub i nettleseren. På Windows skjer det av seg selv ved første push (Git Credential Manager). Ellers bruker du `gh auth login --web`. Forklar henne at hun bare skal godkjenne i nettleseren.
   - Har hun ikke gjort steg 4, kan du klone https://github.com/schrbben/hjemme-app-mal og pushe til et nytt privat repo på hennes konto. Det krever ingen innlogging hos eieren av malen.
2. **Databasen.** Finn Supabase-prosjektet hennes med Supabase-koblingen, og kjør `supabase/oppsett.sql`, for eksempel med `apply_migration`.
   - Hent prosjektadressen og den offentlige nøkkelen.
   - Bruk helst den gamle **anon**-nøkkelen (JWT, begynner med `eyJ`). Koden bruker `@supabase/supabase-js` 2.39. Finnes bare en ny `sb_publishable_…`-nøkkel og den gir feil, oppgrader `@supabase/supabase-js`.
3. **Vercel.** Med Vercel-koblingen legger du inn `NEXT_PUBLIC_SUPABASE_URL` og `NEXT_PUBLIC_SUPABASE_ANON_KEY` for alle miljøer.
   - Godkjenning: hvis koblingen mangler tilgang til teamet hennes, lag en godkjenningslenke med `authorize_team_access`. Den går ut etter 10 minutter, så lag en ny ved behov.
4. **Varselnøkler.** Lag VAPID-nøkler med `npx web-push generate-vapid-keys` direkte inn i `.env.local`, uten å skrive dem ut.
   - Legg `NEXT_PUBLIC_VAPID_PUBLIC_KEY` inn i Vercel selv.
   - Den private nøkkelen (`VAPID_PRIVATE_KEY`) skal ikke innom deg. Legg den på utklippstavla hennes uten å vise den: `Set-Clipboard` i PowerShell på Windows, `pbcopy` på Mac.
   - La henne lime den inn under **Vercel → prosjektet → Settings → Environment Variables**, med **Sensitive** og **Production + Preview**. Tøm utklippstavla etterpå.
5. **Legg ut på nytt.** Push en commit, så Vercel bygger med de nye variablene.
6. **Morgenvarselet.** Bytt ut `DIN-APP.vercel.app` i `supabase/varsel.sql` med adressen hennes, og kjør fila. Den skrur på pg_net og pg_cron i Supabase, som vekker `/api/rydding/varsel` hvert kvarter.
7. **Sjekk at alt virker:**
   - Åpne `/`, `/bod` og `/rydding`.
   - Kall `https://<adresse>/api/rydding/varsel?dryRun` fra Supabase med `net.http_get`. Bruk ikke curl, fordi Vercel ofte blokkerer gjentatte kall derfra.
   - Hjelp henne med steg 7 og et testvarsel under Rydding → ⚙️.

### B. Spør hva hun ønsker

Når appen virker, still disse spørsmålene, gjerne noen få om gangen:

- **Delene:** vil hun ha alle tre? Det hun ikke trenger, kan fjernes fra appvelgeren (`components/AppSwitcher.tsx`) og rutene.
- **Boden:** dette er det viktigste å få riktig.
  - Hvor mange boder har hun, og hvilke mål har de: lengde, bredde, høyde, hvor døra er, og om det er skråtak?
  - Hvilke hyller har hun: merke eller mål, antall hyllenivåer, hvor mange bokser per nivå, og hvor i rommet de står?
  - Hvilke bokstyper har hun? Be om bilder.
  - Har boksene nummer? Hvis ikke: foreslå å nummerere dem med lapper.
  - Romgeometrien ligger i `ROOMS` i `lib/storage.ts`, og hylleplasseringen i `SHELF_LAYOUT` i `components/bod/StorageScene.tsx`. Originalen er en kjellerbod på 2 × 3 m med to Biltema-hyller og en loftsbod med skråtak.
- **Innholdet i boksene:** har hun lister, notater eller bilder? Det raskeste er at hun tar bilder av innholdet, eller lister det opp. Så legger du det inn i databasen for henne, i stedet for at hun taster alt i appen.
- **Fryseren:** hvem deler den?
- **Rydding:**
  - Hvilken dag er ryddedag, og hvor mye tid har hun i uka?
  - Gå gjennom de 48 startoppgavene sammen med henne. Hva passer, hva skal bort, og hvilke intervaller og tider stemmer?
  - Når gjorde hun ting sist? Det kan hun legge inn under ⚙️ → *Legg inn sist gjort*.
- **Hvem skal bruke appen**, og på hvilke telefoner? På iPhone må appen ligge på Hjem-skjermen for å få varsler.
- **Personvern:** appen har ingen innlogging, så alle med lenken kan se og endre. Forklar dette. Vil hun ha innlogging, kan det bygges senere.

### C. Gode vaner videre

- **Små steg:** gjør én endring om gangen. Test den lokalt med `npm run dev` og demodata (`/bod?demo`, `/rydding?demo`), og vis henne resultatet før du pusher. En push til `main` legges ut automatisk.
- **Databaseendringer:** lagre hver endring som en ny nummerert fil i `supabase/`, kjør den med Supabase-koblingen, og sjekk resultatet.
- **Gratisplanene:**
  - Supabase setter prosjekter på pause etter 7 dager uten bruk. `vercel.json` har en daglig jobb (`/api/keepalive`) som hindrer det, og varseljobben holder databasen i gang i tillegg.
  - Vercel Hobby er for privat bruk.
- **Når appen er ferdig**, kan hun si opp Claude Pro. Fortell henne det.
