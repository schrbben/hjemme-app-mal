-- Morgenvarsel for Rydding: databasen vekker varselsiden hvert kvarter.
-- Varselsiden sender bare når det er ryddedag, klokka har passert varseltidspunktet
-- og dagens varsel ikke er sendt, så det kommer maks ett varsel per dag.
--
-- FØR DU KJØRER: bytt ut DIN-APP.vercel.app under med adressen til appen.
-- Kjøres etter supabase/oppsett.sql, og etter at appen er lagt ut på Vercel.

create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

select cron.unschedule(jobid) from cron.job where jobname = 'rydding-varsel';
select cron.schedule(
  'rydding-varsel',
  '*/15 * * * *',
  $$ select net.http_get(url := 'https://DIN-APP.vercel.app/api/rydding/varsel', timeout_milliseconds := 15000) $$
);
