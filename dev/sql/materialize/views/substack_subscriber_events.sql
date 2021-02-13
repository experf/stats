CREATE OR REPLACE MATERIALIZED VIEW substack_subscriber_events AS
  SELECT
    data ->> 'app' as app,
    data ->> 'type' as type,
    data ->> 'subtype' as subtype,
    data ->> 'email' as email,
    CAST(data -> 'src' ->> 'timestamp' as TIMESTAMPTZ) as created_at,
    data -> 'src' ->> 'text' as action_text,
    data -> 'src' ->> 'url' as action_url,
    data -> 'src' ->> 'post_url' as post_url
  FROM events
  WHERE data ->> 'type' = 'substack.subscriber.event';
