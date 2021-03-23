from clavier import sh, CFG

def add_to(subparsers):
    _parser = subparsers.add_parser(
        "console",
        target=run,
        help="Start the `psql` console connected to the Contex database",
    )


def run():
    repo_config = sh.get(
        "mix", "config.get", {"output": "json"},
        ":cortex", "Cortex.Repo",
        format="json",
        chdir=CFG.stats.paths.UMBRELLA
    )

    sh.replace(
        "psql",
        {"pset": "expanded=auto"},
        {k:v for k, v in repo_config.items() if k in ("username", "password")},
        repo_config["database"]
    )
