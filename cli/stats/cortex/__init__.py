from . import console, db, phx

def add_to(subparsers):
    parser = subparsers.add_parser(
        'cortex',
        help="The main Stats app -- Phoenix, Elixir, Erlang, Postgres",
    )

    subparsers = parser.add_subparsers()

    for cmd in (console, db, phx):
        cmd.add_to(subparsers)
