from clavier import sh, log as logging, cfg

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    subparsers.add_parser(
        "cfg",
        target=run,
        help="Dump config",
    )

def run():
    return cfg.to_dict()
