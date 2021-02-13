def add_to(subparsers):
    parser = subparsers.add_parser(
        'scrape',
        help="Scrape stuff up (off the web)",
    )

    parser.add_children(__name__, __path__)
