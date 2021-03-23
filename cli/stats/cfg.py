from pathlib import Path

from clavier import CFG, io

with CFG.configure("stats", src=__file__) as stats:
    stats.name = "stats"

    with stats.configure("log") as log:
        log.level = "INFO"

    with stats.configure("paths") as paths:
        paths.repo = Path(__file__).resolve().parents[2]
        paths.dev = paths.repo / "dev"
        paths.tmp = paths.repo / "tmp"
        # paths.cli = paths.repo / "cli"
        # paths.cli_docs = paths.cli / "docs"
        paths.umbrella = paths.repo
        paths.umbrella_build = paths.umbrella / "_build"
        paths.cortex = paths.umbrella / "apps" / "cortex"
        paths.cortex_web = paths.umbrella / "apps" / "cortex_web"

        with paths.configure("cli") as cli:
            cli.root = paths.repo / "cli"

            with cli.configure("docs") as docs:
                docs.root = cli.root / "docs"
                docs.build = docs.root / "_build"

        with paths.configure("webpack") as webpack:
            webpack.hard_source_cache = \
                paths.cortex_web / "assets" / "node_modules" / ".cache"

    with stats.configure("kafka") as kafka:
        kafka.host = "localhost"
        kafka.port = 9091
        kafka.netloc = f"{kafka.host}:{kafka.port}"
        kafka.servers = [kafka.netloc]
        kafka.topic = "events"

    with stats.configure("materialize") as materialize:
        with materialize.configure("paths") as paths:
            paths.scripts = stats.paths.dev / "sql" / "materialize"

        with materialize.configure("postgres") as postgres:
            postgres.username = "materialized"
            postgres.host = "localhost"
            postgres.port = 6875
            postgres.database = "materialize"
            postgres.url = (
                "postgres://"
                f"{postgres.username}@{postgres.host}:{postgres.port}"
                f"/{postgres.database}"
            )

with CFG.configure(io.rel, src=__file__) as rel:
    rel.to = CFG.stats.paths.repo
