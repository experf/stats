from typing import *
import os
import logging
from . import materialize, paths

NAME = "stats"

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
