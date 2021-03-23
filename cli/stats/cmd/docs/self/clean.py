from clavier import log as logging, CFG, sh

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    subparsers.add_parser(
        "clean",
        target=run,
        help="Remove generated CLI docs"
    )

def run():
    docs = CFG.stats.paths.cli.docs.root
    for module_name in ("clavier", "stats"):
        sh.file_absent(docs / f"{module_name}.rst")
        for path in docs.glob(f"{module_name}.*.rst"):
            path.unlink()
    for path in (
        CFG.stats.paths.cli.docs.build,
        docs / "modules.rst",
        docs / "setup.rst"
    ):
        sh.file_absent(path)


