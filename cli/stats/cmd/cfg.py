from clavier import sh, log as logging, CFG

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    subparsers.add_parser(
        "cfg",
        target=run,
        help="Dump config",
    )

def run():
    return CFG.to_dict()
