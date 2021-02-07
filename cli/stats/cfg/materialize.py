
__all__ = ["postgres"]

class Postgres:
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

postgres = Postgres()
