from stats import sh, cfg

def add_to(subparsers):
    parser = subparsers.add_parser(
        "server",
        help="Become `mix phx.server`",
    )
    parser.set_defaults(func=run)


def run(_args):
    sh.replace(
        "mix",
        "phx.server",
        chdir=cfg.paths.REPO / "umbrella",
        opts_style=" ",
    )
