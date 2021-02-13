import pkgutil
import importlib.util
import sys

from stats import log as logging, dyn


LOG = logging.getLogger(__name__)


def add_to(subparsers):
    for module in dyn.children_modules(__name__, __path__):
        if hasattr(module, "add_to"):
            module.add_to(subparsers)
