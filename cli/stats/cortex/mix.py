from stats import sh, cfg, log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "mix",
        help="Run `mix` in `@/umbrella` from ANYWHERE (in the tree)!",
    )
    parser.add_argument(
        "-c",
        "--cortex",
        action="store_true",
        help=(
            f"Run in the `cortex` app ({cfg.paths.rel(cfg.paths.CORTEX)})",
        )
    )
    parser.add_argument(
        "-w",
        "--cortex_web",
        action="store_true",
        help=(
            "Run in the `cortex_web` app "
            f"({cfg.paths.rel(cfg.paths.CORTEX_WEB)})"
        )
    )
    parser.add_argument("argv", nargs="+", help="Arg values to pass to `mix`")
    parser.set_defaults(func=run)

def run(args):
    if args.cortex is True:
        chdir = cfg.paths.CORTEX
    elif args.cortex_web is True:
        chdir = cfg.paths.CORTEX_WEB
    else:
        chdir = cfg.paths.UMBRELLA

    sh.replace("mix", *args.argv, chdir=chdir)
