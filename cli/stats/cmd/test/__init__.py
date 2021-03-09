def add_to(subparsers):
    parser = subparsers.add_parser('test', help="Run tests",)
    parser.add_children(__name__, __path__)
