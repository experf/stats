import csv

from rich.table import Table
from rich.style import Style
from rich.text import Text

from clavier import log as logging, io, CFG

LOG = logging.getLogger(__name__)

DEFAULT_LENGTH = 8

def csv_path():
    return CFG.stats.paths.dev / "ref" / "theatre-terms.csv"

def add_to(subparsers):
    parser = subparsers.add_parser(
        "names",
        target=run,
        help=(f"Filter short names from {io.fmt(csv_path())}"),
    )
    parser.add_argument(
        "-l",
        "--limit",
        default=DEFAULT_LENGTH,
        type=int,
        help=("Name length limit to filter by"),
    )


def run(limit):
    with csv_path().open("r") as file:
        return [row for row in csv.reader(file) if len(row[0]) <= limit]

class View(io.View):
    def render_rich(self):
        table = Table.grid(padding=(1, 2))
        table.add_column("Term")
        table.add_column("Description")

        for row in self.data:
            table.add_row(
                Text(row[0].lower(), Style(bold=True)),
                row[1],
            )

        self.print(table)
