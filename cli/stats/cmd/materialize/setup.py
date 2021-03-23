from clavier import sh, log as logging, CFG

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    subparsers.add_parser(
        "setup",
        target=run,
        help="Setup Materialized sources and views",
    )


def run():
    views_dir = CFG.stats.paths.DEV / "sql" / "materialize" / "views"

    sh.run(
        "psql",
        CFG.stats.materialize.postgres.url,
        text=True,
        input=(views_dir / "events_bytes.sql"),
    )

    sh.run(
        "psql",
        CFG.stats.materialize.postgres.url,
        text=True,
        input=(views_dir / "events.sql"),
    )

    sh.run(
        "psql",
        CFG.stats.materialize.postgres.url,
        text=True,
        input=(views_dir / "substack_subscriber_events.sql"),
    )
