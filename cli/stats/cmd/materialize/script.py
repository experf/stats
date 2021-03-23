from clavier import sh, log as logging, CFG

LOG = logging.getLogger(__name__)

def rel_paths():
    return [
        str(path.relative_to(CFG.stats.materialize.paths.scripts))
        for path
        in CFG.stats.materialize.paths.scripts.glob("**/*.sql")
    ]

def add_to(subparsers):
    parser = subparsers.add_parser(
        "script",
        target=run,
        help="Run a script",
    )

    parser.add_argument(
        "path",
        choices=rel_paths(),
        help="SQL script to run"
    )


def run(path):
    abs_path = CFG.stats.materialize.paths.scripts / path

    sh.run(
        "psql",
        CFG.stats.materialize.postgres.url,
        text=True,
        input=abs_path,
    )

