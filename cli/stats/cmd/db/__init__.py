def add_to(subparsers):
    parser = subparsers.add_parser(
        'db',
        help="Postgres database -- Phoenix data storage",
    )

    parser.add_children(__name__, __path__)
