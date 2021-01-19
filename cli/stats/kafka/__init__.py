from stats import log as logging
from . import consume

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        'kafka',
        help="Screw around with Kafka",
    )

    subparsers = parser.add_subparsers()

    for cmd in (consume,):
        cmd.add_to(subparsers)
