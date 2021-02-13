from stats import sh, cfg, log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "console",
        target=run,
        help="Start the `psql` console connected to the Materialized database",
    )


def run():
    LOG.info(
        "Connecting to Materialize...",
        url=cfg.materialize.postgres.url,
    )
    sh.replace(
        "psql",
        {"pset": "expanded=auto"},
        cfg.materialize.postgres.url
    )
