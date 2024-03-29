from clavier import sh, CFG

def add_to(subparsers):
    parser = subparsers.add_parser(
        "iex",
        target=run,
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

def run(args=tuple()):
    sh.replace(
        "iex",
        {
            "erl": "-kernel shell_history enabled",
            "dot-iex": CFG.stats.paths.DEV / ".iex.exs",
        },
        "-S", "mix", *args,
        chdir=CFG.stats.paths.UMBRELLA,
        opts_style=" ",
    )
