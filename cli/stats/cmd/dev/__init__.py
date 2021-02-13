from stats import log as logging
from stats.io import OUT

from . import scratch, names

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "dev",
        help="Stuff used developing this CLI and the rest of the app",
    )
    # parser.add_argument(
    #     "argv",
    #     nargs="...",
    #     help="Extra args!",
    # )
    # parser.set_run(run)

    subparsers = parser.add_subparsers()

    for cmd in (names, scratch):
        cmd.add_to(subparsers)

def run(argv=tuple()):
    LOG.info("DEV DEV DEV!", argv=argv)
