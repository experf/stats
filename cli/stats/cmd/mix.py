from stats import sh, cfg, log as logging

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
            for f in (cfg.paths.UMBRELLA / "apps").iterdir()
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
        chdir = cfg.paths.UMBRELLA
    else:
        chdir = cfg.paths.UMBRELLA / "apps" / app

    sh.replace("mix", *args, chdir=chdir)
