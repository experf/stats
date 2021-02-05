from . import db, dev, docker_compose, iex, kafka, mix, phx, scrape

def add_to(subparsers):
    for cmd in (db, dev, docker_compose, iex, kafka, mix, phx, scrape):
        cmd.add_to(subparsers)
