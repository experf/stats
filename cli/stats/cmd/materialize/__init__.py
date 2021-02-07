from stats import log as logging
from . import console, setup

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        'materialize',
        help="Materialize -- Streaming SQL query engine",
    )

    subparsers = parser.add_subparsers()

    for cmd in (console, setup):
        cmd.add_to(subparsers)
