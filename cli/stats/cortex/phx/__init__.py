from . import console

def add_to(subparsers):
    parser = subparsers.add_parser(
        'phx',
        help="Do Phoenix things",
    )

    subparsers = parser.add_subparsers()

    for cmd in (console,):
        cmd.add_to(subparsers)

