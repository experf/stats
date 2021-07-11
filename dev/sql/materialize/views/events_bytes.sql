-- change to localhost:9091 for prod
CREATE SOURCE IF NOT EXISTS events_bytes
  FROM KAFKA BROKER 'kafka1:19091' TOPIC 'events'
  FORMAT BYTES;
