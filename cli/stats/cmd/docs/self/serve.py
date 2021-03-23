from functools import partial
from http.server import SimpleHTTPRequestHandler, test

from clavier import log as logging, CFG

LOG = logging.getLogger(__name__)

DEFAULT_PORT = 4002
DEFAULT_BIND = "127.0.0.1"


def add_to(subparsers):
    parser = subparsers.add_parser(
        "serve", target=run, help="Serve self (CLI) documentation"
    )
    parser.add_argument(
        "-p", "--port", type=int, help="Port to serve on", default=DEFAULT_PORT
    )
    parser.add_argument(
        "-b", "--bind", help="Address to bind to", default=DEFAULT_BIND
    )


def run(bind: str = DEFAULT_BIND, port: int = DEFAULT_PORT):
    # SEE https://github.com/python/cpython/blob/1e5d33e9b9b8631b36f061103a30208b206fd03a/Lib/http/server.py#L1273
    # SEE https://github.com/python/cpython/blob/1e5d33e9b9b8631b36f061103a30208b206fd03a/Lib/http/server.py#L1233
    test(
        HandlerClass=partial(
            SimpleHTTPRequestHandler,
            directory=CFG.stats.paths.cli.docs.build / "html",
        ),
        port=port,
        bind=bind,
    )
