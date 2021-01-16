from stats import sh, cfg, log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "mix",
        help="Run `mix` in `@/umbrella` from ANYWHERE (in the tree)!",
    )
    parser.add_argument("argv", nargs="+", help="Arg values to pass to `mix`")
    parser.set_defaults(func=run)

def run(args):
    sh.replace("mix", *args.argv, chdir=cfg.paths.UMBRELLA)
