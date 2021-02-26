import csv

from rich.table import Table
from rich.style import Style
from rich.text import Text

from stats import log as logging, cfg
from stats.io import OUT, fmt

LOG = logging.getLogger(__name__)

CSV_PATH = cfg.paths.DEV / "ref" / "theatre-terms.csv"
DEFAULT_LENGTH = 8


def add_to(subparsers):
    parser = subparsers.add_parser(
        "names",
        target=run,
        help=(f"Filter short names from {fmt(CSV_PATH)}"),
    )
    parser.add_argument(
        "-l",
        "--limit",
        default=DEFAULT_LENGTH,
        type=int,
        help=("Name length limit to filter by"),
    )


def run(limit):
    with CSV_PATH.open("r") as file:
        reader = csv.reader(file)
        matches = [row for row in reader if len(row[0]) <= limit]

        table = Table.grid(padding=(1, 2))
        table.add_column("Term")
        table.add_column("Description")

        for row in matches:
            table.add_row(
                Text(row[0].lower(), Style(bold=True)),
                row[1],
            )

        OUT.print(table)
