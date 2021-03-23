from clavier import log as logging, sh, CFG

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "docker-compose",
        target=run,
        help=(
            "Docker Compose -- runs Zookeeper and Kafka.\n"
            "\n"
            "This command proxies arguments through to `docker-compose`,\n"
            f"prepending `--project-name {CFG.stats.name}`"
        ),
    )

    parser.add_argument(
        "args",
        nargs="...",
        help="Extra args and opts to pass to `docker-compose`",
    )


def run(args=tuple()):
    sh.run(
        "docker-compose",
        "--project-name", CFG.stats.name,
        *args,
        chdir=CFG.stats.paths.dev,
    )
