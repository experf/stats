from shutil import rmtree
import os

from stats import sh, cfg, log as logging, etc

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "phx",
        help="Phoenix server",
    )
    parser.add_argument(
        "-c",
        "--clean",
        action="store_true",
        help=(
            "Remove build files before starting "
            f"({etc.fmt(cfg.paths.UMBRELLA_BUILD)}).\n"
            "\n"
            "**WARNING**  This incurs a *significant* start-up cost, but has \n"
            "             proven to resolve odd compilation issues that \n"
            "             `mix clean` does not."
        ),
    )
    parser.add_argument(
        "-i",
        "--iex",
        action="store_true",
        help=(
            "Run the server inside the `iex` REPL. Same as \n"
            "`stats iex phx.server` but you get additional options here."
        ),
    )
    parser.add_argument(
        "--rm-hs-cache",
        action="store_true",
        help=(
            "Remove the `hard-source-webpack-plugin` cache before starting \n"
            "the server.\n"
            "\n"
            "If auto-reload breaks and you see output at startup like:\n"
            "\n"
            "    [hardsource:6435fcbe] Cache is corrupted.\n"
            "    Error: ENOENT: no such file or directory, [...]\n"
            "\n"
            "then this might fix your problem.\n"
            "\n"
            "SEE https://github.com/nrser/stats/issues/2"
        ),
    )

    parser.set_defaults(func=run)


def run(clean=False, iex=False, rm_hs_cache=False, **_kwds):
    if rm_hs_cache:
        sh.file_absent(
            cfg.paths.WEBPACK_HARD_SOURCE_CACHE,
            name="`hard-source-webpack-plugin` cache directory"
        )

    if clean:
        sh.file_absent(
            cfg.paths.UMBRELLA_BUILD,
            name="umbrella build directory"
        )

    if iex:
        sh.replace(
            "iex",
            {
                "erl": "-kernel shell_history enabled",
                "dot-iex": cfg.paths.DEV / ".iex.exs",
            },
            "-S",
            "mix",
            "phx.server",
            chdir=cfg.paths.UMBRELLA,
            opts_style=" ",
        )
    else:
        sh.replace(
            "mix",
            "phx.server",
            chdir=cfg.paths.UMBRELLA,
            opts_style=" ",
            env={
                **os.environ,
                "STATS_CLI_CWD": os.getcwd(),
            },
        )