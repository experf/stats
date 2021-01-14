from . import console, reset

def add_to(subparsers):
    parser = subparsers.add_parser(
        'db',
        help="Do database stuff (Postgres)",
    )

    subparsers = parser.add_subparsers()

    for cmd in (console, reset):
        cmd.add_to(subparsers)

