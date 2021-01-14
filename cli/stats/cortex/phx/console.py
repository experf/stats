from stats import sh, cfg

def add_to(subparsers):
    parser = subparsers.add_parser(
        "console",
        help="Start the server *inside* the Elixir `iex` REPL",
    )
    parser.set_defaults(func=run)


def run(_args):
    sh.replace(
        "iex",
        {
            "erl": "-kernel shell_history enabled",
            "dot-iex": cfg.paths.DEV / ".iex.exs",
        },
        "-S", "mix", "phx.server",
        chdir=cfg.paths.UMBRELLA,
        opts_style=" ",
    )
