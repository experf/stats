from . import paths as _paths

class _Paths:
    scripts = _paths.DEV / "sql" / "materialize"
class _Postgres:
    username = "materialized"
    host = "localhost"
    port = 6875
    database = "materialize"

    @property
    def url(self):
        return (
            f"postgres://{self.username}@{self.host}:{self.port}"
            f"/{self.database}"
        )

paths = _Paths()
postgres = _Postgres()
