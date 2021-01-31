from stats import log as logging
from . import console, db, phx, server, mix, scrape

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        'cortex',
        help="The main Stats app -- Phoenix, Elixir, Erlang, Postgres",
    )

    subparsers = parser.add_subparsers()

    for cmd in (console, db, mix, phx, scrape, server):
        cmd.add_to(subparsers)
