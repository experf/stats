from rich.table import Table
from rich.style import Style
from rich.text import Text

from clavier import log as logging, io

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    _parser = subparsers.add_parser(
        "scratch",
        target=run,
        help=(
            "Trying shit out. Don't run w/o reading the source unless "
            "you _really_ like suprises."
        ),
    )

class View(io.View):
    def render_rich(self):
        table = Table()
        table.add_column("Name")
        table.add_column("Favorite Color")

        for entry in self.data:
            table.add_row(
                Text(entry["name"], Style(bold=True, color="blue")),
                entry["fav_color"],
            )

        self.print(table)

# Idea for dropping `add_to()`... would eventually want to get at least `help`
# from the docstring...
#
# @cmd(
#     "scratch",
#     help="Scratch it up!",
#     args=[
#         arg("args", nargs="...", help="Assorted shit."),
#     ]
# )
def run():
    data = [
        {"name": "Neil", "fav_color": "gray"},
        {"name": "Mica", "fav_color": "shinny"},
    ]

    return View(data)
