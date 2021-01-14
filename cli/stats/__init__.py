from typing import *
import sys
import os
import logging
import argparse

import argcomplete

from .io import ERR
from .log import setup
from . import cortex

LOG = logging.getLogger(__name__)


class ArgumentParser(argparse.ArgumentParser):
    def __init__(self, *args, **kwds):
        super().__init__(*args, **kwds)

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


def make_parser() -> ArgumentParser:
    parser = ArgumentParser()
    subparsers = parser.add_subparsers(help="Select a command")
    for cmd in (cortex,):
        cmd.add_to(subparsers)
    return parser


def log_level_for(verbosity: Optional[int]) -> int:
    if verbosity is None:
        return logging.INFO
    else:
        return logging.DEBUG


def run():
    parser = make_parser()
    argcomplete.autocomplete(parser)
    args = parser.parse_args()
    log_level = log_level_for(args.verbose)

    setup(level=log_level)

    log = LOG.getChild("run")

    # pylint: disable=broad-except

    try:
        args.func(args)
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
