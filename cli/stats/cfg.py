from pathlib import Path
import os
import logging

class paths:
    REPO = Path(__file__).resolve().parents[2]
    DEV = REPO / "dev"
    UMBRELLA = REPO / "umbrella"
    CORTEX = UMBRELLA / "apps" / "cortex"
    CORTEX_WEB = UMBRELLA / "apps" / "cortex_web"


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

