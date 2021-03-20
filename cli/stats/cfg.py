from pathlib import Path

from clavier import cfg, log as logging, io

with cfg.configure("stats", src=__file__) as stats:
    stats.name = "stats"

    with stats.configure("log") as log:
        log.level = "info"

    with stats.configure("paths") as paths:
        paths.repo = Path(__file__).resolve().parents[2]
        paths.dev = paths.repo / "dev"
        paths.cli = paths.repo / "cli"
        paths.umbrella = paths.repo
        paths.umbrella_build = paths.umbrella / "_build"
        paths.cortex = paths.umbrella / "apps" / "cortex"
        paths.cortex_web = paths.umbrella / "apps" / "cortex_web"

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

with cfg.configure(io.rel, src=__file__) as rel:
    rel.to = cfg.stats.paths.repo
