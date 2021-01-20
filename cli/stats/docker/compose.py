from stats import log as logging, cfg, sh

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "compose",
        help="Pass args into `docker-compose`, adding the project name",
    )
    parser.add_argument(
        "argv",
        nargs="*",
        help="Extra args and opts to pass to `docker-compose up`",
    )
    parser.set_defaults(func=run)


def run(args):
    sh.run(
        "docker-compose",
        "--project-name", cfg.NAME,
        *args.argv,
        chdir=cfg.paths.DEV,
    )
