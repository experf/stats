from clavier import sh, log as logging, cfg

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    subparsers.add_parser(
        "setup",
        target=run,
        help="Setup Materialized sources and views",
    )


def run():
    views_dir = cfg.paths.DEV / "sql" / "materialize" / "views"

    sh.run(
        "psql",
        cfg.materialize.postgres.url,
        text=True,
        input=(views_dir / "events_bytes.sql"),
    )

    sh.run(
        "psql",
        cfg.materialize.postgres.url,
        text=True,
        input=(views_dir / "events.sql"),
    )

    sh.run(
        "psql",
        cfg.materialize.postgres.url,
        text=True,
        input=(views_dir / "substack_subscriber_events.sql"),
    )
