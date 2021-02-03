from stats import log as logging

from . import scratch

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "dev",
        help="Stuff used developing this CLI and the rest of the app",
    )
    subparsers = parser.add_subparsers()

    for cmd in (scratch,):
        cmd.add_to(subparsers)
