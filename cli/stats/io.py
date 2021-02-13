import sys
from pathlib import Path

from rich.console import Console
from rich.theme import Theme

from stats import cfg

THEME = Theme(
    {
        "good": "bold green",
        "yeah": "bold green",
        "bad": "bold red",
        "uhoh": "bold red",
        "holup": "bold yellow",
        "todo": "bold yellow",
    }
)

OUT = Console(theme=THEME, file=sys.stdout)
ERR = Console(theme=THEME, file=sys.stderr)

def fmt_path(path: Path) -> str:
    # pylint: disable=bare-except
    try:
        return f"//{Path(path).relative_to(cfg.paths.REPO)}"
    except:
        return str(path)


def fmt(x):
    if isinstance(x, Path):
        return fmt_path(x)
    return str(x)
