from __future__ import annotations
import logging
from typing import (
    Any,
    Literal,
    Optional,
    Union,
    Dict,
    cast,
)

# Some way of complaining (ideally) _outside_ the logging system, to (try) to
# avoid recursive self-destruction (yeah, I did see something about telling the
# warning system to go through logging, so it might still explode...)
from warnings import warn

from .. import txt, err
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

LEVEL_NAMES: Dict[str, TLevel] = dict(
    CRITICAL=CRITICAL,
    FATAL=FATAL,
    ERROR=ERROR,
    WARNING=WARNING,
    WARN=WARN,
    INFO=INFO,
    DEBUG=DEBUG,
    NOTSET=NOTSET,
)


def _root_name(module_name: str) -> str:
    return module_name.split(".")[0]


def _announce_debug(logger):
    logger.debug(
        "[logging.level.debug]DEBUG[/logging.level.debug] logging "
        f"[on]ENABLED[/on] for {logger.name}.*"
    )


def level_for(value: Union[str, int]) -> TLevel:
    """
    Make a `logging` level `int` from things you might get from an ENV var or,
    say, a human being.

    ## Examples

    1.  Integer levels can be provided as strings:

            >>> level_for("10")
            10

    2.  Levels we don't know get a puke:

            >>> level_for("8")
            Traceback (most recent call last):
                ...
            ValueError: Unknown log level integer 8; known levels are 50 (CRITICAL), 50 (FATAL), 40 (ERROR), 30 (WARNING), 30 (WARN), 20 (INFO), 10 (DEBUG) and 0 (NOTSET)

    3.  We also accept level *names* (gasp!), case-insensitive:


            >>> level_for("debug")
            10
            >>> level_for("DEBUG")
            10

    4.  Everything else can kick rocks:

            >>> level_for([])
            Traceback (most recent call last):
                ...
            clavier.err.ArgTypeError: Expected `value` to be `str` or `int`, given `list`: []
    """

    if isinstance(value, str):
        if value.isdigit():
            return level_for(int(value))
        cap_value = value.upper()
        if cap_value in LEVEL_NAMES:
            return LEVEL_NAMES[cap_value]
        raise ValueError(
            f"Unknown log level name {repr(value)}; known level names are "
            f"{', '.join(LEVEL_NAMES.keys())} (case-insensitive)"
        )
    if isinstance(value, int):
        if value in LEVEL_NAMES.values():
            return cast(TLevel, value)
        levels = txt.coordinate(
            [f"{v} ({k})" for k, v in LEVEL_NAMES.items()], "and", to_s=str
        )
        raise ValueError(
            f"Unknown log level integer {value}; known levels are {levels}"
        )
    raise err.ArgTypeError("value", (str, int), value)


def get_logger(*name: str) -> LogGetter:
    """\
    Returns a proxy to a logger where construction is deferred until first use.

    See `clavier.log.LogGetter`.
    """
    return LogGetter(*name)


def get_lib_logger() -> LogGetter:
    return get_logger(_root_name(__name__))


def set_lib_level(level: Union[str, int]) -> None:
    logger = get_lib_logger()
    logger.setLevel(level_for(level))
    if level == DEBUG:
        _announce_debug(logger)


def get_pkg_logger(module_name: str) -> LogGetter:
    return get_logger(_root_name(module_name))


def set_pkg_level(module_name: str, level: Union[str, int]) -> None:
    logger = get_pkg_logger(module_name)
    logger.setLevel(level_for(level))
    if level == DEBUG:
        _announce_debug(logger)


def set_level(
    module_name,
    *,
    level: Union[None, str, int] = None,
    verbosity: Optional[int] = None,
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


def setup(module_name: str, level: TLevel = INFO) -> None:
    logging.setLoggerClass(KwdsLogger)

    set_lib_level(WARNING)
    set_pkg_level(module_name, level)

    rich_handler = RichHandler.singleton()
    get_lib_logger().addHandler(rich_handler)
    get_pkg_logger(module_name).addHandler(rich_handler)


# Support the weird camel-case that stdlib `logging` uses...
getLogger = get_logger
setLevel = set_level


if __name__ == '__main__':
    import doctest
    doctest.testmod()
