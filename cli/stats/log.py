from __future__ import annotations
import logging
import sys
from typing import *

# Some way of complaining (ideally) _outside_ the logging system, to (try) to
# avoid recursive self-destruction (yeah, I did see something about telling the
# warning system to go through logging, so it might still explode...)
# from warnings import warn

from rich.table import Table
from rich.console import Console, ConsoleRenderable, RichCast
from rich.text import Text
from rich.style import Style
# from rich.containers import Renderables
from rich.traceback import Traceback
from rich.pretty import Pretty

from .io import OUT, ERR
from . import cfg

CRITICAL = logging.CRITICAL  # 50
FATAL = logging.FATAL  # ↑
ERROR = logging.ERROR  # 40
WARNING = logging.WARNING  # 30
WARN = logging.WARN  # ↑
INFO = logging.INFO  # 20
DEBUG = logging.DEBUG  # 10
NOTSET = logging.NOTSET  # 0


def is_rich_renderable(x: Any) -> bool:
    return isinstance(x, (ConsoleRenderable, RichCast))  # , str))


def get_pkg_logger():
    return logging.getLogger(__name__.split(".")[0])


def setup(level: Optional[int] = None) -> None:
    logging.setLoggerClass(KwdsLogger)

    pkg_logger = get_pkg_logger()

    if level is None:
        pkg_logger.setLevel(cfg.log.level)
    else:
        pkg_logger.setLevel(level)

    pkg_logger.addHandler(RichHandler.singleton())


def set_pkg_level(level: int) -> None:
    get_pkg_logger().setLevel(level)


class LogGetter:
    def __init__(self, *args, **kwds):
        self._args = args
        self._kwds = kwds

    @property
    def _logger(self):
        return logging.getLogger(*self._args, **self._kwds)

    def __getattr__(self, name):
        return getattr(self._logger, name)


def getLogger(*args, **kwds):
    return LogGetter(*args, **kwds)


class KwdsLogger(logging.getLoggerClass()):
    def _log(
        self,
        level,
        msg,
        args,
        exc_info=None,
        extra=None,
        stack_info=False,
        **data,
    ):
        """
        Low-level log implementation, proxied to allow nested logger adapters.
        """

        if extra is not None:
            if isinstance(extra, dict):
                extra = {"data": data, **extra}
        else:
            extra = {"data": data}

        super()._log(
            level,
            msg,
            args,
            exc_info=exc_info,
            stack_info=stack_info,
            extra=extra,
        )


class RichHandler(logging.Handler):
    # Default consoles, pointing to the two standard output streams
    DEFAULT_CONSOLES = dict(
        out=OUT,
        err=ERR,
    )

    # By default, all logging levels log to the `err` console
    DEFAULT_LEVEL_MAP = {
        logging.CRITICAL: "err",
        logging.ERROR: "err",
        logging.WARNING: "err",
        logging.INFO: "err",
        logging.DEBUG: "err",
    }

    @classmethod
    def singleton(cls) -> RichHandler:
        instance = getattr(cls, "__singleton", None)
        if instance is not None and instance.__class__ == cls:
            return instance
        instance = cls()
        setattr(cls, "__singleton", instance)
        return instance

    def __init__(
        self,
        level: int = logging.NOTSET,
        *,
        consoles: Optional[Mapping[str, Console]] = None,
        level_map: Optional[Mapping[str, str]] = None,
    ):
        super().__init__(level=level)

        if consoles is None:
            self.consoles = self.DEFAULT_CONSOLES.copy()
        else:
            self.consoles = {**self.DEFAULT_CONSOLES, **consoles}

        if level_map is None:
            self.level_map = self.DEFAULT_LEVEL_MAP.copy()
        else:
            self.level_map = {**self.DEFAULT_LEVEL_MAP, **level_map}

    def emit(self, record):
        # pylint: disable=broad-except
        try:
            self._emit_table(record)
        except (KeyboardInterrupt, SystemExit) as error:
            # We want these guys to bub' up
            raise error
        except Exception as error:
            ERR.print_exception()
            # self.handleError(record)

    def _emit_table(self, record):
        # SEE   https://github.com/willmcgugan/rich/blob/25a1bf06b4854bd8d9239f8ba05678d2c60a62ad/rich/_log_render.py#L26

        console = self.consoles.get(
            self.level_map.get(record.levelno, "err"),
            ERR,
        )

        output = Table.grid(padding=(0, 1))
        output.expand = True

        # Left column -- log level, time
        output.add_column(
            style=f"logging.level.{record.levelname.lower()}",
            width=8,
        )

        # Main column -- log name, message, args
        output.add_column(ratio=1, style="log.message", overflow="fold")

        output.add_row(
            Text(record.levelname),
            Text(record.name, Style(color="blue", dim=True)),
        )

        if record.args:
            msg = str(record.msg) % record.args
        else:
            msg = str(record.msg)

        output.add_row(None, msg)

        if hasattr(record, "data") and record.data:
            table = Table.grid(padding=(0, 1))
            table.expand = True
            table.add_column()
            table.add_column()
            for key, value in record.data.items():
                rich_key = Text(key, Style(color="blue", italic=True))
                if is_rich_renderable(value):
                    rich_value = value
                else:
                    rich_value = Pretty(value)
                table.add_row(rich_key, rich_value)
            output.add_row(None, table)

        if record.exc_info:
            output.add_row(None, Traceback.from_exception(*record.exc_info))

        console.print(output)
