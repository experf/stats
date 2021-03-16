from clavier import log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        'kafka',
        help="Apache Kafka -- event data storage",
    )

    parser.add_children(__name__, __path__)

