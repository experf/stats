import logging

from stats import sh, cfg

from .. import docker_compose

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "reset",
        help="Clear Kafka data",
    )

    parser.set_defaults(func=run)


def run(**_kwds):
    LOG.info("[holup]Resetting Kafka data...[/holup]")

    docker_compose.run(["down"])

    sh.file_absent(
        cfg.paths.DEV / "data",
        name="docker-compose data directory"
    )

    docker_compose.run(["up", "--detach"])

    LOG.info("[yeah]Kafka data reset.[/yeah]")

