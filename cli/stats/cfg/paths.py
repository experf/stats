from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
DEV = REPO / "dev"

UMBRELLA = REPO / "umbrella"
UMBRELLA_BUILD = UMBRELLA / "_build"

CORTEX = UMBRELLA / "apps" / "cortex"

CORTEX_WEB = UMBRELLA / "apps" / "cortex_web"
CORTEX_WEB_ASSETS = CORTEX_WEB / "assets"
WEBPACK_HARD_SOURCE_CACHE = CORTEX_WEB_ASSETS / "node_modules" / ".cache"

def rel( path: Path, to: Path=REPO) -> Path:
    return path.relative_to(to)
