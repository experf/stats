from stats import sh, cfg, log as logging

LOG = logging.getLogger(__name__)

def rel_paths():
    return [
        str(path.relative_to(cfg.materialize.paths.scripts))
        for path
        in cfg.materialize.paths.scripts.glob("**/*.sql")
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
    abs_path = cfg.materialize.paths.scripts / path

    sh.run(
        "psql",
        cfg.materialize.postgres.url,
        text=True,
        input=abs_path,
    )

