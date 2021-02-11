from stats import sh, cfg, log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "docs",
        help="Generate documentation",
    )
    parser.set_func(run)

def run(**_kwds):
    sh.run(
        "mix",
        "docs",
        {
            "formatter": "html",
            "output": cfg.paths.CORTEX_WEB / "priv" / "static" / "docs",
        },
        chdir=cfg.paths.UMBRELLA
    )
