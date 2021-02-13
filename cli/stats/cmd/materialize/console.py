from stats import sh, cfg, log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "console",
        help="Start the `psql` console connected to the Materialized database",
    )
    parser.set_run(run)


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
