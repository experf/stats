import sys

from stats import log as logging

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    _parser = subparsers.add_parser(
        "scratch",
        target=run,
        help=(
            "Trying shit out. Don't run w/o reading the source unless "
            "you _really_ like suprises."
        ),
    )


def run():
    LOG.info("SCRATCH!!!!", argv=sys.argv)
