from stats import log as logging, cfg, sh

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "down",
        help="Bring the Docker services down with `docker-compose`",
    )
    parser.add_argument(
        "argv",
        nargs="*",
        help="Extra args and opts to pass to `docker-compose down`",
    )
    parser.set_defaults(func=run)


def run(args):
    sh.run(
        "docker-compose",
        "--project-name", cfg.NAME,
        "down",
        *args.argv,
        chdir=cfg.paths.DEV,
    )