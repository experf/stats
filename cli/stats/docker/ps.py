from stats import log as logging, cfg, sh

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "ps",
        aliases=["status", "show"],
        help="Show the Docker services",
    )
    parser.add_argument(
        "argv",
        nargs="*",
        help="Extra args and opts to pass to `docker-compose ps`",
    )
    parser.set_defaults(func=run)


def run(args):
    sh.run(
        "docker-compose",
        "--project-name", cfg.NAME,
        "ps",
        *args.argv,
        chdir=cfg.paths.DEV,
    )
