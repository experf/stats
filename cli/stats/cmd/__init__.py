from . import (
    db,
    dev,
    docker_compose,
    docs,
    iex,
    kafka,
    materialize,
    mix,
    phx,
    scrape,
)


def add_to(subparsers):
    for cmd in (
        db,
        dev,
        docker_compose,
        docs,
        iex,
        kafka,
        materialize,
        mix,
        phx,
        scrape,
    ):
        cmd.add_to(subparsers)
