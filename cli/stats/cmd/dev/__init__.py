from stats import log as logging

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "dev",
        help="Stuff used developing this CLI and the rest of the app",
    )

    # parser.add_argument(
    #     "--blah",
    #     choices=["one", "two"],
    #     help="BLAH!",
    # )

    # parser.add_argument(
    #     "argv",
    #     nargs="...",
    #     help="Extra args!",
    # )
    # parser.set_run(run)

    parser.add_children(__name__, __path__)


def run(argv=tuple()):
    LOG.info("DEV DEV DEV!", argv=argv)
