from clavier import sh, log as logging, cfg

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "deps",
        target=run,
        help="Get and compile Elixir deps with `mix`",
    )

def run():
    sh.run(
        "mix",
        "do",
        "deps.get,",
        "deps.compile",
        chdir=cfg.paths.UMBRELLA
    )
