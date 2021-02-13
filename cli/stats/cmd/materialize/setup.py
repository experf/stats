from stats import sh, cfg, log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    _parser = subparsers.add_parser(
        "setup",
        target=run,
        help="Setup Materialized sources and views",
    )


def run():
    sh.run(
        "psql",
        cfg.materialize.postgres.url,
        text=True,
        input=(
            "CREATE SOURCE IF NOT EXISTS events_bytes\n"
            "  FROM KAFKA BROKER 'kafka1:19091' TOPIC 'events'\n"
            "  FORMAT BYTES;"
        )
    )

    sh.run(
        "psql",
        cfg.materialize.postgres.url,
        text=True,
        input=(
            "CREATE OR REPLACE MATERIALIZED VIEW events AS\n"
            "  SELECT CAST(data AS jsonb) AS data\n"
            "  FROM (\n"
            "    SELECT convert_from(data, 'utf8') AS data\n"
            "    FROM events_bytes\n"
            "  );"
        )
    )
