from __future__ import annotations
from typing import *

from clavier import log as logging, io, Sesh, cfg
from clavier.argument_parser import ArgumentParser

import stats.cfg # NEED this! And FIRST!
from stats import cmd

LOG = logging.getLogger(__name__)


def run():
    sesh = Sesh(__name__, cfg.stats.paths.cli / "README.md", cmd.add_to)
    sesh.setup(cfg.log.level)
    sesh.parse()
    sesh.exec()
