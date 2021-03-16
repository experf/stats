from clavier import sh, log as logging, cfg

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

    paths = cfg[__package__, "paths"]

    sh.run("mix", "ecto.reset", chdir=paths.cortex)

    LOG.info("[yeah]Database reset.[/yeah]")

    if serve:
        LOG.info("[holup]Starting Phoenix server...[/holup]")

        sh.replace("mix", "phx.server", chdir=paths.umbrella)
