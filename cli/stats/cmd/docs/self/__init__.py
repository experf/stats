def add_to(subparsers):
    parser = subparsers.add_parser(
        'self',
        aliases=["cli"],
        help="Documentation stuff",
    )
    parser.add_children(__name__, __path__)
