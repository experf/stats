from __future__ import annotations
import logging
from typing import (
    Any,
    Literal,
    Optional,
)
# Some way of complaining (ideally) _outside_ the logging system, to (try) to
# avoid recursive self-destruction (yeah, I did see something about telling the
# warning system to go through logging, so it might still explode...)
from warnings import warn

from .kwds_logger import KwdsLogger
from .log_getter import LogGetter
from .rich_handler import RichHandler

TLevel = Literal[
    logging.CRITICAL,
    logging.ERROR,
    logging.WARNING,
    logging.INFO,
    logging.DEBUG,
    logging.NOTSET,
]

# Re-defining log levels allows using this module to be swapped in for basic
# uses of stdlib `logging`.
CRITICAL = logging.CRITICAL  # 50
FATAL = logging.FATAL  # ↑
ERROR = logging.ERROR  # 40
WARNING = logging.WARNING  # 30
WARN = logging.WARN  # ↑
INFO = logging.INFO  # 20
DEBUG = logging.DEBUG  # 10
NOTSET = logging.NOTSET  # 0

def _root_name(module_name: str) -> str:
    return module_name.split(".")[0]

def _announce_debug(logger):
    logger.debug(
        "[logging.level.debug]DEBUG[/logging.level.debug] logging "
        f"[on]ENABLED[/on] for {logger.name}.*"
    )

def get_logger(*name: str) -> LogGetter:
    """\
    Returns a proxy to a logger where construction is deferred until first use.

    See `clavier.log.LogGetter`.
    """
    return LogGetter(*name)

def get_lib_logger() -> LogGetter:
    return get_logger(_root_name(__name__))

def set_lib_level(level: TLevel) -> None:
    logger = get_lib_logger()
    logger.setLevel(level)
    if level == DEBUG:
        _announce_debug(logger)

def get_pkg_logger(module_name: str) -> LogGetter:
    return get_logger(_root_name(module_name))

def set_pkg_level(module_name: str, level: TLevel) -> None:
    logger = get_pkg_logger(module_name)
    logger.setLevel(level)
    if level == DEBUG:
        _announce_debug(logger)

def set_level(
    module_name,
    *,
    level: Optional[int]=None,
    verbosity: Optional[int]=None
):
    if level is not None:
        set_pkg_level(level)
    if verbosity is not None:
        if verbosity == 0:
            set_pkg_level(module_name, INFO)
        elif verbosity == 1:
            set_pkg_level(module_name, DEBUG)
        elif verbosity == 2:
            set_pkg_level(module_name, DEBUG)
            set_lib_level(INFO)
        elif verbosity == 3:
            set_pkg_level(module_name, DEBUG)
            set_lib_level(DEBUG)
        elif verbosity > 3:
            set_pkg_level(module_name, DEBUG)
            set_lib_level(DEBUG)
            get_logger(__name__).warn(
                f"`verbosity` > 3 has no effect, given {verbosity}"
            )
        else:
            raise ValueError(
                "Expected `verbosity` to be `int` such that "
                f"`0 <= verbosity <= 3`, given {type(verbosity)}: {verbosity}"
            )

def setup(module_name: str, level: TLevel=INFO) -> None:
    logging.setLoggerClass(KwdsLogger)

    set_lib_level(WARNING)
    set_pkg_level(module_name, level)

    rich_handler = RichHandler.singleton()
    get_lib_logger().addHandler(rich_handler)
    get_pkg_logger(module_name).addHandler(rich_handler)

# Support the weird camel-case that stdlib `logging` uses...
getLogger = get_logger
setLevel = set_level
