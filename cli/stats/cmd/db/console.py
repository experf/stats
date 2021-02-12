from stats import sh, cfg

def add_to(subparsers):
    parser = subparsers.add_parser(
        "console",
        help="Start the `psql` console connected to the Contex database",
    )
    parser.set_defaults(func=run)


def run(**_kwds):
    repo_config = sh.get(
        "mix", "config.get", {"output": "json"},
        ":cortex", "Cortex.Repo",
        format="json",
        chdir=cfg.paths.UMBRELLA
    )

    sh.replace(
        "psql",
        {"pset": "expanded=auto"},
        {k:v for k, v in repo_config.items() if k in ("username", "password")},
        repo_config["database"]
    )
