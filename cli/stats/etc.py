from typing import *
from pathlib import Path
# from os import PathLike

from stats import cfg, log as logging

LOG = logging.getLogger(__name__)

# pylint: disable=bare-except

def fmt_path(path: Path) -> str:
    LOG.debug("HERE", rel=Path(path).relative_to(cfg.paths.REPO))
    try:
        return f"//{Path(path).relative_to(cfg.paths.REPO)}"
    except:
        return str(path)

def fmt(x):
    if isinstance(x, Path):
        return fmt_path(x)
    return str(x)
