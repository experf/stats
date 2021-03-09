from stats import log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    subparsers.add_parser(
        "self",
        target=run,
        help="Test the CLI code itself"
    )

def run():
    return None

