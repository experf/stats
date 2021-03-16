import logging

from clavier import sh, cfg

from .. import docker_compose

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    _parser = subparsers.add_parser(
        "reset",
        target=run,
        help="Clear Kafka data",
    )


def run():
    LOG.info("[holup]Resetting Kafka data...[/holup]")

    docker_compose.run(["down"])

    sh.file_absent(
        cfg.paths.DEV / "data",
        name="docker-compose data directory"
    )

    docker_compose.run(["up", "--detach"])

    LOG.info("[yeah]Kafka data reset.[/yeah]")

