from typing import *
import sys
import os
import argparse

import argcomplete
from rich.markdown import Markdown

from . import log as logging, cmd, cfg
from .io import ERR

LOG = logging.getLogger(__name__)


class ArgumentParser(argparse.ArgumentParser):
    def __init__(self, *args, **kwds):
        super().__init__(
            *args, formatter_class=argparse.RawTextHelpFormatter, **kwds
        )

        self.add_argument(
            "-v",
            "--verbose",
            action="count",
            help="Make noise.",
        )

        # self.add_argument(
        #     '--log',
        #     type=str,
        #     help="File path to write logs to.",
        # )

        self.add_argument(
            "--backtrace",
            action="store_true",
            help="Print backtraces on error",
        )

    def set_func(self, func):
        self.set_defaults(func=func)


def make_parser() -> ArgumentParser:
    with (cfg.paths.CLI / "README.md").open("r") as file:
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


def run():
    logging.setup()

    log = LOG.getChild("run")
    log.debug("[holup]Handling command...[/holup]", argv=sys.argv)

    parser = make_parser()
    argcomplete.autocomplete(parser)
    args = parser.parse_args()
    log_level = log_level_for(args.verbose)

    logging.set_pkg_level(log_level)

    # pylint: disable=broad-except

    try:
        args.func(**args.__dict__)
    except KeyboardInterrupt:
        pass
    except Exception as error:
        if (
            args.backtrace
            or log_level == logging.DEBUG
            or "STATS_BACKTRACE" in os.environ
        ):
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
