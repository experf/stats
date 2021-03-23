from clavier import sh, log as logging, CFG

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "mix",
        target=run,
        help="Run `mix` in `//umbrella` from ANYWHERE (in the tree)!",
    )
    parser.add_argument(
        "-a",
        "--app",
        choices=[
            f.name
            for f in (CFG.stats.paths.umbrella / "apps").iterdir()
            if f.is_dir() and (f / "mix.exs").is_file()
        ],
        help="Run in a specific app directory",
    )
    parser.add_argument(
        "args",
        nargs="...",
        help="Arguments to pass to `mix`"
    )

def run(args=tuple(), app=None):
    if app is None:
        chdir = CFG.stats.paths.umbrella
    else:
        chdir = CFG.stats.paths.umbrella / "apps" / app

    sh.replace("mix", *args, chdir=chdir)
