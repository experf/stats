def add_to(subparsers):
    parser = subparsers.add_parser('docs', help="Documentation stuff",)
    parser.add_children(__name__, __path__)
