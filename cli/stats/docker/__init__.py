from stats import log as logging

from . import up, down, ps, compose

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "docker",
        help="Interact with `docker-compose`",
    )
    subparsers = parser.add_subparsers()

    for cmd in (up, down, ps, compose):
        cmd.add_to(subparsers)
