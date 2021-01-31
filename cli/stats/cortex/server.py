from shutil import rmtree

from stats import sh, cfg, log as logging, etc

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "server",
        help="Become `mix phx.server`",
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

    parser.add_argument("-c", "--clean", action="store_true", help=(
        "Remove build files before starting "
        f"({etc.fmt(cfg.paths.UMBRELLA_BUILD)}).\n"
        "\n"
        "**WARNING**  This incurs a *significant* start-up cost, but has \n"
        "             proven to resolve odd compilation issues that \n"
        "             `mix clean` does not."
    ))

    parser.set_defaults(func=run)


def run(args):
    if args.rm_hs_cache:
        if cfg.paths.WEBPACK_HARD_SOURCE_CACHE.exists():
            LOG.info(
                "[holup]"
                "Removing `hard-source-webpack-plugin` cache directory..."
                "[/holup]",
                path=etc.fmt(cfg.paths.WEBPACK_HARD_SOURCE_CACHE),
            )
            rmtree(cfg.paths.WEBPACK_HARD_SOURCE_CACHE)
        else:
            LOG.info(
                "[yeah]"
                "`hard-source-webpack-plugin` cache already gone"
                "[/yeah]",
                path=etc.fmt(cfg.paths.WEBPACK_HARD_SOURCE_CACHE),
            )

    if args.clean:
        if cfg.paths.UMBRELLA_BUILD.exists():
            LOG.info(
                "[holup]"
                "Removing umbrella build directory..."
                "[/holup]",
                path=etc.fmt(cfg.paths.UMBRELLA_BUILD),
            )
            rmtree(cfg.paths.UMBRELLA_BUILD)
        else:
            LOG.info(
                "[yeah]"
                "Umbrella build directory already gone"
                "[/yeah]",
                path=etc.fmt(cfg.paths.UMBRELLA_BUILD),
            )

    sh.replace(
        "mix",
        "phx.server",
        chdir=cfg.paths.REPO / "umbrella",
        opts_style=" ",
    )
