import sys
import shlex

from rich.console import Console
from rich.theme import Theme
from rich.syntax import Syntax

THEME = Theme(
    {
        "good": "bold green",
        "bad": "bold red",
    }
)

OUT = Console(theme=THEME, file=sys.stdout)
ERR = Console(theme=THEME, file=sys.stderr)

def sh(cmd):
    if not isinstance(cmd, str):
        cmd = shlex.join(cmd)
    return Syntax("\n  ".join(cmd.splitlines()), "bash")
