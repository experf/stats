from inspect import cleandoc

from clavier import log as logging, CFG, sh

from .serve import run as _serve, DEFAULT_PORT, DEFAULT_BIND
from .clean import run as _clean

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "build", target=run, help="Build self (CLI) documentation"
    )
    parser.add_argument(
        "-o",
        "--open",
        action="store_true",
        help="Open the index.html after building.",
    )
    parser.add_argument(
        "-s",
        "--serve",
        action="store_true",
        help="Start a lil' Python server for the docs after building",
    )
    parser.add_argument(
        "-c",
        "--clean",
        action="store_true",
        help="Clean first",
    )
    parser.add_argument(
        "-p", "--port", type=int, help="Port to serve on", default=DEFAULT_PORT
    )
    parser.add_argument(
        "-b", "--bind", help="Address to bind to", default=DEFAULT_BIND
    )


@LOG.inject
def run(
    log,
    open: bool = False,
    serve: bool = False,
    clean: bool = False,
    port: int = DEFAULT_PORT,
    bind: str = DEFAULT_BIND,
):
    paths = CFG.stats.paths

    if clean is True:
        _clean()

    exclude = ["setup.py"]

    sh.run(
        log,
        "sphinx-apidoc",
        {
            "output-dir": paths.cli.docs.root,
            "ext-doctest": True,
            "force": True,
            "private": True,
            "separate": True,
            # "suffix": "gen.rst", # Ends up in URL
        },
        paths.cli.root,
        *exclude,
        chdir=paths.cli.root,
        rel_paths=True,
    )

    sh.run(log, "make", "html", chdir=paths.cli.docs.root)

    if serve is True:
        if open is True:
            host = "localhost" if bind in ("", "0.0.0.0", "127.0.0.1") else bind
            sh.run(log, "open", f"http://{host}:{port}")
        _serve(port=port, bind=bind)
    elif open is True:
        sh.run(
            log,
            "open", paths.cli.docs.build / "html" / "index.html",
            rel_paths=True,
        )
