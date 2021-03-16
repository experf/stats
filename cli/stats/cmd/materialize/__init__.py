from clavier import log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        'materialize',
        help="Materialize -- Streaming SQL query engine",
    )

    parser.add_children(__name__, __path__)
