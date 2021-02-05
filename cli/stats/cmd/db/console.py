from stats import sh, cfg

def add_to(subparsers):
    parser = subparsers.add_parser(
        "console",
        help="Start the `psql` console connected to the Contex database",
        # aliases=["c"],
    )
    parser.set_defaults(func=run)


def run(**_kwds):
    repo_config = sh.get(
        "mix", "config.repo", fmt="json", chdir=cfg.paths.UMBRELLA
    )

    sh.replace(
        "psql",
        {k:v for k, v in repo_config.items() if k in ("username", "password")},
        repo_config["database"]
    )