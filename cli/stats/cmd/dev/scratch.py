import sys

from stats import log as logging

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "scratch",
        help=(
            "Trying shit out. Don't run w/o reading the source unless "
            "you _really_ like suprises."
        ),
    )
    parser.set_defaults(func=run)


def run(**_kwds):
    LOG.info("SCRATCH!!!!", argv=sys.argv)
