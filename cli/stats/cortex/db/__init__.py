from . import console

def add_to(subparsers):
    parser = subparsers.add_parser(
        'db',
        help="Do database stuff (Postgres)",
    )

    subparsers = parser.add_subparsers()

    for cmd in (console,):
        cmd.add_to(subparsers)

