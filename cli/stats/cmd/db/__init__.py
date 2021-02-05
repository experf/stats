from . import console, reset

def add_to(subparsers):
    parser = subparsers.add_parser(
        'db',
        help="Postgres database -- Phoenix data storage",
    )

    subparsers = parser.add_subparsers()

    for cmd in (console, reset):
        cmd.add_to(subparsers)
