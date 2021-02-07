CREATE OR REPLACE MATERIALIZED VIEW substack_subscriber_events AS
  SELECT
    data ->> 'app' as app,
    data -> 'src' ->> 'post_url' as post_url,
    data -> 'src' ->> 'text' as action,
    data -> 'src' ->> 'url' as action_url
  FROM events;
