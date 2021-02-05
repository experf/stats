from stats import log as logging
from . import consume, reset

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        'kafka',
        help="Apache Kafka -- event data storage",
    )

    subparsers = parser.add_subparsers()

    for cmd in (consume, reset):
        cmd.add_to(subparsers)
