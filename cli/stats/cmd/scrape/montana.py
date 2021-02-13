import re

import requests
from bs4 import BeautifulSoup
from rich.table import Table

from stats.etc import find_map
from stats.io import OUT

GOLD_URL = "https://www.montana-cans.com/en/spray-cans/montana-spray-paint/gold-400ml-artist-paint/montana-gold-400ml-colors"
BLACK_URL = "https://www.montana-cans.com/en/spray-cans/montana-spray-paint/black-50ml-600ml-graffiti-paint/montana-black-400ml"

def add_to(subparsers):
    parser = subparsers.add_parser(
        "montana",
        target=run,
        help="Scrape colors off montana-cans.com for (S)CSS (ab)use",
    )


def run():
    page = requests.get(GOLD_URL)
    soup = BeautifulSoup(page.content, "html.parser")

    table = Table.grid(padding=(0, 1))
    table.add_column()
    table.add_column()
    table.add_column()

    for label in soup("label", class_="color--option--label"):
        hex_ = label["data-hex"]
        name = find_map(
            lambda node: node.name is None and node.string.strip(),
            label.contents,
            nothing=(None, False, "")
        )

        var_name = re.sub(r"[^a-z0-9]+", "-", name.lower())
        table.add_row(
            f"$mtn-{var_name}:",
            f"{hex_};",
            f"// {name}",
        )

    OUT.print(table)
