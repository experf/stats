CREATE OR REPLACE MATERIALIZED VIEW events AS
  SELECT CAST(data AS jsonb) AS data
  FROM (
    SELECT convert_from(data, 'utf8') AS data
    FROM events_bytes
  );