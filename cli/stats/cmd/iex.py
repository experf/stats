from stats import sh, cfg

def add_to(subparsers):
    parser = subparsers.add_parser(
        "iex",
        aliases=["console"],
        help="Elixir REPL, run in the mix environment",
    )
    parser.add_argument(
        "args",
        nargs="*",
        help=(
            "Arguments to pass to `mix`, such as `phx.server` to run the\n"
            "Phoenix server in the `iex` console."
        ),
    )
    parser.set_defaults(func=run)

def run(args=tuple(), **_opts):
    sh.replace(
        "iex",
        {
            "erl": "-kernel shell_history enabled",
            "dot-iex": cfg.paths.DEV / ".iex.exs",
        },
        "-S", "mix", *args,
        chdir=cfg.paths.REPO / "umbrella",
        opts_style=" ",
    )
