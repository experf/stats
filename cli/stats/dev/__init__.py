from stats import log as logging

from . import scratch, names

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "dev",
        help="Stuff used developing this CLI and the rest of the app",
    )
    subparsers = parser.add_subparsers()

    for cmd in (names, scratch):
        cmd.add_to(subparsers)
