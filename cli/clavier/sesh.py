"""The `Sesh` class."""

from __future__ import annotations
from typing import (
    Union,
    Callable,
    Optional,
)
from pathlib import Path
import argparse
import sys

from . import log as logging, err, io
from .arg_par import ArgumentParser

class Sesh:
    """\
    A CLI app session
    """

    log: logging.LogGetter = logging.getLogger(__name__, "Sesh")

    pkg_name: str
    parser: ArgumentParser
    _args: Optional[argparse.Namespace]

    def __init__(
        self: Sesh,
        pkg_name: str,
        description: Union[str, Path],
        subparser_hook: Callable[[argparse._SubParsersAction], None]
    ):
        self._args = None
        self.pkg_name = pkg_name
        self.parser = ArgumentParser.create(description, subparser_hook)

    @property
    def args(self):
        if self._args is None:
            raise err.InternalError("Must `parse()` first to populate `args`")
        return self._args

    def is_backtracing(self) -> bool:
        return self.parser.is_backtracing(self.pkg_name, self.args)

    def setup(self: Sesh, log_level: logging.TLevel) -> Sesh:
        logging.setup(self.pkg_name, log_level)
        return self

    @log.inject
    def parse(self, log, *args, **kwds) -> Sesh:
        self._args = self.parser.parse_args(*args, **kwds)
        logging.set_level(self.pkg_name, verbosity=self.args.verbose)
        log.debug("Parsed arguments", **self._args.__dict__)
        return self

    @log.inject
    def run(self, log) -> int:
        if not hasattr(self.args, "__target__"):
            log.error("Missing __target__ arg", self_args=self.args)
            raise err.InternalError("Missing __target__ arg")

        # Form the call keyword args -- start with a dict of the parsed arguments
        kwds = {**self.args.__dict__}
        # Remove the global argument names
        for key in self.parser.action_dests():
            if key in kwds:
                del kwds[key]
        # And the `__target__` that holds the target function
        del kwds["__target__"]

        # pylint: disable=broad-except
        try:
            result = self.args.__target__(**kwds)
        except KeyboardInterrupt:
            # sys.exit(0)
            return 0
        except Exception as error:
            if self.is_backtracing():
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
            # sys.exit(1)
            return 1

        if not isinstance(result, io.View):
            result = io.View(result)

        try:
            result.render(self.args.output)
        except KeyboardInterrupt:
            sys.exit(0)
        except Exception as error:
            if self.is_backtracing():
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
            # sys.exit(1)
            return 1

        # sys.exit(0)
        return 0

    def exec(self):
        sys.exit(self.run())
