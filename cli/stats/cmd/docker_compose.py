from stats import log as logging

from stats import cfg, sh

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "docker-compose",
        help=(
            "Docker Compose -- runs Zookeeper and Kafka.\n"
            "\n"
            "This command proxies arguments through to `docker-compose`,\n"
            f"prepending `--project-name {cfg.NAME}`"
        ),
    )

    parser.add_argument(
        "args",
        nargs="...",
        help="Extra args and opts to pass to `docker-compose`",
    )
    parser.set_run(run)


def run(args=tuple()):
    sh.run(
        "docker-compose",
        "--project-name", cfg.NAME,
        *args,
        chdir=cfg.paths.DEV,
    )
