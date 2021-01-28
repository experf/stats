from pathlib import Path
import os
import logging


NAME = "stats"

class paths:
    REPO = Path(__file__).resolve().parents[2]
    DEV = REPO / "dev"
    UMBRELLA = REPO / "umbrella"
    CORTEX = UMBRELLA / "apps" / "cortex"
    CORTEX_WEB = UMBRELLA / "apps" / "cortex_web"
    CORTEX_WEB_ASSETS = CORTEX_WEB / "assets"
    WEBPACK_HARD_SOURCE_CACHE = CORTEX_WEB_ASSETS / "node_modules" / ".cache"

    @classmethod
    def rel(cls, path: Path, to: Path=REPO) -> Path:
        return path.relative_to(to)

class log:
    @classmethod
    @property
    def level(cls):
        if os.environ.get("STATS_DEBUG", "") != "":
            return logging.DEBUG
        return logging.INFO
        # name = "STATS_" + "_".join((s.upper() for s in path))
        # if name in os.environ:
        #     env_str = os.environ[name]

