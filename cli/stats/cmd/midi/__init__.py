from clavier import log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        'midi',
        help="Stream MIDI events through system",
    )

    parser.add_children(__name__, __path__)
