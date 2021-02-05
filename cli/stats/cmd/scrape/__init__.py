from . import montana

def add_to(subparsers):
    parser = subparsers.add_parser(
        'scrape',
        help="Scrape stuff up (off the web)",
    )

    subparsers = parser.add_subparsers()

    for cmd in (montana,):
        cmd.add_to(subparsers)

