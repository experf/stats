from pathlib import Path

from clavier import cfg

def repo_path(path: Path) -> Path:
    return path.relative_to(cfg["stats.paths.repo"])

# @cfg.inject_kwds
# def rel(path: Path, to: Path) -> Path:
#     return path.relative_to(to)

def fmt_path(path: Path) -> str:
    # pylint: disable=bare-except
    try:
        return f"//{rel(path)}"
    except:
        return str(path)