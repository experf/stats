from typing import *
import sys
from pathlib import Path
import json

from rich.console import Console, ConsoleRenderable, RichCast
from rich.theme import Theme
from rich.pretty import Pretty

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

def is_rich(x: Any) -> bool:
    return isinstance(x, (ConsoleRenderable, RichCast))

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


def render_to_console(data, console=OUT):
    if data is None:
        pass
    elif isinstance(data, str) or is_rich(data):
        console.print(data)
    elif isinstance(data, list):
        for entry in data:
            render_to_console(entry, console=console)
    else:
        console.print(Pretty(data))

class View:
    DEFAULT_FORMAT = "rich"

    def __init__(self, data, console=OUT):
        self.data = data
        self.console = console

    def print(self, *args, **kwds):
        self.console.print(*args, **kwds)

    def render(self, format=DEFAULT_FORMAT):
        method_name = f"render_{format}"
        method = getattr(self, method_name)

        if method is None:
            raise RuntimeError(
                f"Output format {format} not supported by {self.__class__} "
                "view (method `{method_name}` does not exist)"
            )
        if not callable(method):
            raise RuntimeError(
                f"Internal error -- found attribute `{method_name}` on "
                f"{self.__class__} view, but it is not callable."
            )

        method()

    def render_json(self):
        self.print(
            json.dumps(self.data, indent=2)
        )

    def render_rich(self):
        render_to_console(self.data, console=self.console)
