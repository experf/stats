from pathlib import Path

class paths:
    REPO = Path(__file__).resolve().parents[2]
    DEV = REPO / "dev"
    UMBRELLA = REPO / "umbrella"
    CORTEX = UMBRELLA / "apps" / "cortex"
    CORTEX_WEB = UMBRELLA / "apps" / "cortex_web"
