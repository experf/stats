-- Simplest query -- count total link clicks pointing to the ITP version of
-- the beta sign-up splash page.
-- 
-- To run this:
-- 
-- 1.   Proxy the materilized port locally throught ssh
--      
--          ssh -L 6875:localhost:6875 spf
--      
-- 2.   Run the script using the dev CLI
--      
--          stats materialize script beta/itp/count.sql
-- 
SELECT
  COUNT(*)
FROM events
WHERE
  data ->> 'type' = 'link.click'
  AND data ->> 'dest_url' = 'https://expand.live/k7BBL4';
