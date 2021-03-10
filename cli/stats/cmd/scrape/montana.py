import re

import requests
from bs4 import BeautifulSoup
from rich.table import Table

from stats import log as logging, io, OUTPUT_HELP
from stats.etc import find_map
from stats.io import OUT

LOG = logging.getLogger(__name__)

GOLD_URL = "https://www.montana-cans.com/en/spray-cans/montana-spray-paint/gold-400ml-artist-paint/montana-gold-400ml-colors"
BLACK_URL = "https://www.montana-cans.com/en/spray-cans/montana-spray-paint/black-50ml-600ml-graffiti-paint/montana-black-400ml"

def add_to(subparsers):
    parser = subparsers.add_parser(
        "montana",
        target=run,
        description="Scrape colors off montana-cans.com for (S)CSS (ab)use",
        view=View,
    )

    parser.add_argument(
        "-p", "--var-prefix",
        help="Prefix for SCSS variable names",
        default="mtn",
    )


def run(var_prefix):
    page = requests.get(GOLD_URL)
    soup = BeautifulSoup(page.content, "html.parser")

    table = Table.grid(padding=(0, 1))
    table.add_column()
    table.add_column()
    table.add_column()

    data = []

    for label in soup("label", class_="color--option--label"):
        hex_ = label["data-hex"].replace("#", "")
        name = find_map(
            lambda node: node.name is None and node.string.strip(),
            label.contents,
            nothing=(None, False, "")
        )
        var_name = re.sub(r"[^a-z0-9]+", "-", name.lower())
        data.append({
            "var_name": f"{var_prefix}-{var_name}",
            "hex": hex_,
            "name": name,
        })

    return View(data)


class View(io.View):
    DEFAULT_FORMAT = "scss"

    def render_scss(self):
        """
        Prints the scraped colors as SCSS variables.
        """

        table = Table.grid(padding=(0, 1))
        table.add_column()
        table.add_column()
        table.add_column()

        for color in self.data:
            table.add_row(
                f"${color['var_name']}:",
                f"#{color['hex']};",
                f"// {color['name']}",
            )

        self.print(table)
