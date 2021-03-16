from __future__ import annotations
from typing import *
import sys
import os

from clavier import log as logging, io, Sesh, cfg
from clavier.argument_parser import ArgumentParser

import stats.cfg
from stats import cmd

LOG = logging.getLogger(__name__)


def run():
    Sesh(
        __name__,
        cfg.stats.paths.cli / "README.md",
        cmd.add_to
    ).setup(cfg.log.level).parse().exec()

def old_run():
    logging.setup(__name__, cfg.log.level)

    log = LOG.getChild("run")
    log.debug("[holup]Handling command...[/holup]", argv=sys.argv)

    parser = ArgumentParser.create(cfg.paths.CLI / "README.md", cmd.add_to)
    args = parser.parse_args()
    logging.set_level(__name__, verbosity=args.verbose)

    assert hasattr(args, "__target__")

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
        if parser.is_backtracing(args):
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
        if parser.is_backtracing(args):
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
