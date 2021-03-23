from __future__ import annotations
from typing import *

from clavier import log as logging, io, Sesh, CFG
from clavier.arg_par import ArgumentParser

import stats.cfg # NEED this! And FIRST!
from stats import cmd

LOG = logging.getLogger(__name__)


def run():
    sesh = Sesh(__name__, CFG.stats.paths.cli.root / "README.md", cmd.add_to)
    sesh.setup(CFG.stats.log.level)
    sesh.parse()
    sesh.exec()
