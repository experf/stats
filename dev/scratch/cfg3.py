from typing import (
    List,
)

from pathlib import Path

from clavier import cfg, log as logging, io

from nansi.proper import Prop, Proper

class StatsConfig(Proper):
    class Log(Proper):
        level = Prop(int, logging.INFO, env="STATS_LOG_LEVEL")

    class Paths(Proper):
        repo = Prop(Path, Path(__file__).resolve().parents[2])
        dev = Prop(Path, lambda paths, _prop: paths.repo / "dev")
        cli = Prop(Path, lambda paths, _prop: paths.repo / "cli")
        umbrella = Prop(Path, lambda paths, _prop: paths.repo )
        umbrella_build = Prop(Path, lambda paths, _prop: paths.repo / "_build")
        apps = Prop(Path, lambda paths, _prop: paths.repo / "apps")
        cortex = Prop(Path, lambda paths, _prop: paths.apps / "cortex")
        cortex_web = Prop(Path, lambda paths, _prop: paths.apps / "cortex_web")

    class Kafka(Proper):
        host = Prop(str, "localhost")
        port = Prop(int, 9091)
        netloc = Prop(str, lambda kafka, _: f"{kafka.host}:{kafka.port}")
        servers = Prop(List[str], lambda kafka, _: [kafka.netloc])
        topic = Prop(str, "events")

    class Materialize(Proper):
        class Paths:
            scripts = Prop(Path, "FUCK") # Yeah so that doesn't work...

    log = Prop(Log)
    paths = Prop(Paths)
    kafka = Prop(Kafka)
    materialize = Prop(Materialize)


# with cfg.scope(io.rel, src=__file__) as rel:
#     rel.to = cfg["stats.paths.root"]
