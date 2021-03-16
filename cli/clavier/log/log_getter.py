"""Defines `LogGetter` class."""

import logging
from typing import (
    Any,
)


class LogGetter:
    """\
    Proxy to `logging.Logger` instance that defers construction until use.

    This allows things like:

        LOG = logging.getLogger(__name__)

    at the top scope in files, where it is processed _before_ `setup()` is
    called to switch the logger class. Otherwise, those global definitions would
    end up being regular `logging.Logger` classes that would not support the
    "keyword" log method signature we prefer to use.

    See `KwdsLogger` and `getLogger`.
    """

    name: str

    def __init__(self, *name: str):
        self.name = ".".join(name)

    @property
    def _logger(self) -> logging.Logger:
        return logging.getLogger(self.name)

    def __getattr__(self, name: str) -> Any:
        return getattr(self._logger, name)

    def getChild(self, name):
        return LogGetter(f"{self.name}.{name}")

    def inject(self, fn):
        return lambda *args, **kwds: fn(
            *args, log=self.getChild(fn.__name__), **kwds
        )