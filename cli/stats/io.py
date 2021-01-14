import sys

from rich.console import Console
from rich.theme import Theme

THEME = Theme(
    {
        "good": "bold green",
        "yeah": "bold green",
        "bad": "bold red",
        "uhoh": "bold red",
        "holup": "bold yellow",
    }
)

OUT = Console(theme=THEME, file=sys.stdout)
ERR = Console(theme=THEME, file=sys.stderr)
