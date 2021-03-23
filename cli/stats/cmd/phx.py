import os
from inspect import cleandoc

from clavier import sh, log as logging, io, CFG

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "phx",
        target=run,
        help="Phoenix server",
    )
    parser.add_argument(
        "-c",
        "--clean",
        action="store_true",
        help=cleandoc(
            f"""
            Remove build files before starting ({io.fmt(CFG.stats.paths.umbrella_build)}).

            **WARNING** This incurs a *significant* start-up cost, but has proven to
                        resolve odd compilation issues that `mix clean` does not.
            """
        ),
    )
    parser.add_argument(
        "-i",
        "--iex",
        action="store_true",
        default=False,
        help=cleandoc(
            """
            Run the server inside the `iex` REPL. Same as

                $ stats iex phx.server

            but you get additional options here.
            """
        ),
    )
    parser.add_argument(
        "--no-rm-hs-cache",
        action="store_true",
        help=cleandoc(
            """
            *DON'T* Remove the `hard-source-webpack-plugin` cache before starting the
            server.

            Auto-reload keeps breaking with output at startup like:

                [hardsource:6435fcbe] Cache is corrupted.
                Error: ENOENT: no such file or directory, [...]

            so we are smashing the hard-source cache on start-up.

            SEE https://github.com/nrser/stats/issues/2
            """
        ),
    )


def run(clean=False, iex=False, no_rm_hs_cache=False):
    if no_rm_hs_cache is False:
        sh.file_absent(
            CFG.stats.paths.webpack.hard_source_cache,
            name="`hard-source-webpack-plugin` cache directory",
        )

    if clean:
        sh.file_absent(
            CFG.stats.paths.umbrella_build, name="umbrella build directory"
        )

    if iex:
        sh.replace(
            "iex",
            {
                "erl": "-kernel shell_history enabled",
                "dot-iex": CFG.stats.paths.dev / ".iex.exs",
            },
            "-S",
            "mix",
            "phx.server",
            chdir=CFG.stats.paths.umbrella,
            opts_style=" ",
        )
    else:
        sh.replace(
            "mix",
            "phx.server",
            chdir=CFG.stats.paths.umbrella,
            opts_style=" ",
            env={
                **os.environ,
                "STATS_CLI_CWD": os.getcwd(),
            },
        )
