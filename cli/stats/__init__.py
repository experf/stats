from typing import *
import sys
import os
import argparse
import json

import argcomplete
from rich.markdown import Markdown

from . import log as logging, cmd, cfg, dyn, io

LOG = logging.getLogger(__name__)


_OUTPUT_HELP = (
"""How to print output. Commands can add their own custom output formats, but
pretty much all commands should support `rich` and `json` outputs.

-   `rich` (default) -- Pretty, colorful output for humans via the [rich][]
    Python package.

    [rich]: https://rich.readthedocs.io/en/stable/

-   `json` -- Prints a JSON encoding via `json.dump()`. Uses the `indent=2`
    option to make it easier on the eyes.
"""
)

class ArgumentParser(argparse.ArgumentParser):

    def __init__(self, *args, target=None, **kwds):
        super().__init__(
            *args, formatter_class=argparse.RawTextHelpFormatter, **kwds
        )

        if target is not None:
            self.set_target(target)

        self.add_argument(
            "--backtrace",
            action="store_true",
            help="Print backtraces on error",
        )

        # self.add_argument(
        #     '--log',
        #     type=str,
        #     help="File path to write logs to.",
        # )

        self.add_argument(
            "-v",
            "--verbose",
            action="count",
            help="Make noise.",
        )

        self.add_argument(
            "-o",
            "--output",
            default=io.View.DEFAULT_FORMAT,
            help=_OUTPUT_HELP,
        )

    def set_target(self, target):
        self.set_defaults(__target__=target)

    def action_dests(self):
        return [
            action.dest
            for action in self._actions
            if action.dest != argparse.SUPPRESS
        ]

    def add_children(self, module__name__, module__path__):
        subparsers = self.add_subparsers()

        for module in dyn.children_modules(module__name__, module__path__):
            if hasattr(module, "add_to"):
                module.add_to(subparsers)


def make_parser() -> ArgumentParser:
    with cfg.paths.CLI.joinpath("README.md").open("r") as file:
        description = file.read()

    parser = ArgumentParser(description=description)
    subparsers = parser.add_subparsers(help="Select a command")
    cmd.add_to(subparsers)
    return parser


def log_level_for(verbosity: Optional[int]) -> int:
    if verbosity is None:
        return logging.INFO
    else:
        return logging.DEBUG


def is_backtracing(args, log_level):
    return (
        args.backtrace
        or log_level == logging.DEBUG
        or "STATS_BACKTRACE" in os.environ
    )


def run():
    logging.setup()

    log = LOG.getChild("run")
    log.debug("[holup]Handling command...[/holup]", argv=sys.argv)

    parser = make_parser()
    argcomplete.autocomplete(parser)
    args = parser.parse_args()
    log_level = log_level_for(args.verbose)

    logging.set_pkg_level(log_level)

    # Form the call keyword args -- start with a dict of the parsed arguments
    kwds = {**args.__dict__}
    # Remove the global argument names
    for key in parser.action_dests():
        if key in kwds:
            del kwds[key]
    # And the `__target__` that holds the target function
    del kwds["__target__"]

    # pylint: disable=broad-except
    try:
        result = args.__target__(**kwds)
    except KeyboardInterrupt:
        sys.exit(0)
    except Exception as error:
        if is_backtracing(args, log_level):
            log.error(
                "[holup]Terminting due to unhandled exception[/holup]...",
                exc_info=True,
            )
        else:
            log.error(
                "Command [uhoh]FAILED[/uhoh].\n\n"
                f"{type(error).__name__}: {error}\n\n"
                "Add `--backtrace` to print stack.",
            )
        sys.exit(1)

    if not isinstance(result, io.View):
        result = io.View(result)

    try:
        result.render(args.output)
    except KeyboardInterrupt:
        sys.exit(0)
    except Exception as error:
        if is_backtracing(args, log_level):
            log.error(
                "[holup]Terminting due to view rendering error[/holup]...",
                exc_info=True,
            )
        else:
            log.error(
                "Command [uhoh]FAILED[/uhoh].\n\n"
                f"{type(error).__name__}: {error}\n\n"
                "Add `--backtrace` to print stack.",
            )
        sys.exit(1)

    sys.exit(0)
