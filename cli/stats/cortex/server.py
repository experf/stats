from shutil import rmtree

from stats import sh, cfg, log as logging, etc

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "server",
        help="Become `mix phx.server`",
    )

    # Seeing shit like this on startup, auto-reload breaking...
    #
    #     [hardsource:6435fcbe] Using 1 MB of disk space.
    #     [hardsource:6435fcbe] Using 1 MB of disk space.
    #     [hardsource:6435fcbe] Tracking node dependencies with: yarn.lock.
    #     [hardsource:6435fcbe] Reading from cache 6435fcbe...
    #     [hardsource:6435fcbe] Tracking node dependencies with: yarn.lock.
    #     [hardsource:6435fcbe] Reading from cache 6435fcbe...
    #     [hardsource:6435fcbe] Cache is corrupted.
    #     Error: ENOENT: no such file or directory, rename '/Users/nrser/src/gh/nrser/stats/umbrella/apps/cortex_web/assets/node_modules/.cache/hard-source/6435fcbe1d271f30038570f32400ab9251788c88068473d898ccc8022e38631f/assets-parity~' -> '/Users/nrser/src/gh/nrser/stats/umbrella/apps/cortex_web/assets/node_modules/.cache/hard-source/6435fcbe1d271f30038570f32400ab9251788c88068473d898ccc8022e38631f/assets-parity'
    #     [hardsource:6435fcbe] Last compilation did not finish saving. Building new cache.
    #     [hardsource:6435fcbe] Could not freeze ./node_modules/css-loader/dist/cjs.js!./css/milligram.css: Cannot read property 'hash' of undefined
    #     [hardsource:6435fcbe] Could not freeze ./node_modules/css-loader/dist/runtime/api.js: Cannot read property 'hash' of undefined
    #     [hardsource:6435fcbe] Could not freeze ./css/app.scss: Cannot read property 'hash' of undefined
    #     [hardsource:6435fcbe] Could not freeze ./js/app.js: Cannot read property 'hash' of undefined
    #     [hardsource:6435fcbe] Could not freeze ./node_modules/phoenix_html/priv/static/phoenix_html.js: Cannot read property 'hash' of undefined
    #
    # Whacking `//umbrella/apps/cortex_web/assets/node_modules/.cache` seems to
    # get things back on track (until they break again). Who knows...
    #
    parser.add_argument(
        "--rm-hs-cache",
        action="store_true",
        help=(
            "Remove the `hard-source-webpack-plugin` cache before starting \n"
            "the server. It lives at:\n"
            "\n"
            f"    {etc.fmt(cfg.paths.WEBPACK_HARD_SOURCE_CACHE)}\n"
            "\n"
            "If auto-reload breaks and you see output at startup like:\n"
            "\n"
            "    [hardsource:6435fcbe] Cache is corrupted.\n"
            "    Error: ENOENT: no such file or directory, [...]\n"
            "\n"
            "then this might fix your problem. Cause unknown."
        )
    )
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

    sh.replace(
        "mix",
        "phx.server",
        chdir=cfg.paths.REPO / "umbrella",
        opts_style=" ",
    )
