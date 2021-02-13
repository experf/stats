import logging

from stats import sh, cfg

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "reset",
        target=run,
        help="Wipe and re-create the Cortex database",
    )

    parser.add_argument(
        "-s",
        "--serve",
        help="Replace with a `phx.server` process after reset",
        default=False,
        action="store_true",
    )


def run(serve=False):
    LOG.info("[holup]Resetting Cortex database...[/holup]")

    sh.run("mix", "ecto.reset", chdir=cfg.paths.CORTEX)

    LOG.info("[yeah]Database reset.[/yeah]")

    if serve:
        LOG.info("[holup]Starting Phoenix server...[/holup]")

        sh.replace("mix", "phx.server", chdir=cfg.paths.UMBRELLA)
