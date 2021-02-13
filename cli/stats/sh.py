from typing import *
import logging
import os
from os.path import isabs, basename
import subprocess
from pathlib import Path
import json
from shutil import rmtree

from .io import OUT, ERR, fmt

LOG = logging.getLogger(__name__)

TOpts = Mapping[Any, Any]
TOptsStyle = Literal["=", " "]

DEFAULT_OPTS_STYLE: TOptsStyle = "="
DEFAULT_OPTS_SORT = True


def iter_opt(
    flag: str,
    value: Any,
    style: TOptsStyle,
    is_short: bool,
) -> Generator[str, None, None]:
    if is_short or style == " ":
        yield flag
        yield str(value)
    else:
        yield f"{flag}={value}"


def flat_opts(
    opts: TOpts,
    *,
    style: TOptsStyle = DEFAULT_OPTS_STYLE,
    sort: bool = DEFAULT_OPTS_SORT,
) -> Generator[str, None, None]:
    if opts is None:
        return
    if sort:
        items = sorted(opts.items())
    else:
        items = list(opts.items())
    for name, value in items:
        if value is None:
            continue
        name_s = str(name)
        is_short = len(name_s) == 1
        flag = f"-{name_s}" if is_short else f"--{name_s}"
        if isinstance(value, (list, tuple)):
            for item in value:
                yield from iter_opt(flag, item, style, is_short)
        elif isinstance(value, bool):
            if value is True:
                yield flag
        else:
            yield from iter_opt(flag, value, style, is_short)


def flat_args(
    args,
    *,
    opts_style: TOptsStyle = DEFAULT_OPTS_STYLE,
    opts_sort: bool = DEFAULT_OPTS_SORT,
):
    for arg in args:
        if isinstance(arg, (str, bytes)):
            yield arg
        elif isinstance(arg, Mapping):
            yield from flat_opts(arg, style=opts_style, sort=opts_sort)
        elif isinstance(arg, Sequence):
            yield from flat_args(
                arg, opts_style=opts_style, opts_sort=opts_sort
            )
        else:
            yield str(arg)


def flatten_args(
    args,
    *,
    opts_style: TOptsStyle = DEFAULT_OPTS_STYLE,
    opts_sort: bool = DEFAULT_OPTS_SORT,
):
    return list(flat_args(args, opts_style=opts_style, opts_sort=opts_sort))


# pylint: disable=redefined-builtin
def get(*args, chdir=None, format=None, encoding="utf-8", **opts) -> Any:
    log = LOG.getChild("get")
    if isinstance(chdir, Path):
        chdir = str(chdir)

    cmd = flatten_args(args)

    log.debug(
        "Getting system command output...",
        cmd=cmd,
        chdir=chdir,
        fmt=fmt,
        encoding=encoding,
        **opts,
    )
    # https://docs.python.org/3.8/library/subprocess.html#subprocess.run
    output = subprocess.check_output(cmd, encoding=encoding, cwd=chdir, **opts)

    if format is None:
        return output
    elif format == "json":
        return json.loads(output)
    else:
        log.warn("Unknown `format`", format=format, expected=[None, "json"])
        return output


def run(
    *args, chdir=None, check=True, encoding="utf-8", input=None, **opts
) -> None:
    if isinstance(chdir, Path):
        chdir = str(chdir)
    cmd = flatten_args(args)

    LOG.getChild("get").debug(
        "Running system command...",
        cmd=cmd,
        chdir=chdir,
        encoding=encoding,
        **opts,
    )

    if isinstance(input, Path):
        with input.open("r", encoding="utf-8") as file:
            subprocess.run(
                cmd,
                check=check,
                cwd=chdir,
                encoding=encoding,
                input=file.read(),
                **opts,
            )
    else:
        subprocess.run(
            cmd, check=check, cwd=chdir, encoding=encoding, input=input, **opts
        )


def replace(
    exe: str,
    *args,
    env: Optional[Mapping] = None,
    chdir: Optional[Union[str, Path]] = None,
    opts_style: TOptsStyle = DEFAULT_OPTS_STYLE,
    opts_sort: bool = DEFAULT_OPTS_SORT,
) -> NoReturn:
    # https://docs.python.org/3.9/library/os.html#os.execl
    for console in (OUT, ERR):
        console.file.flush()
    proc_name = basename(exe)
    cmd = flatten_args((exe, *args), opts_style=opts_style, opts_sort=opts_sort)
    LOG.getChild("exec").debug(
        "Replacing current process with system command...",
        cmd=cmd,
        env=env,
        chdir=chdir,
    )
    if chdir is not None:
        os.chdir(chdir)
    if env is None:
        if isabs(exe):
            os.execv(exe, cmd)
        else:
            os.execvp(proc_name, cmd)
    else:
        if isabs(exe):
            os.execve(exe, cmd, env)
        else:
            os.execvpe(proc_name, cmd, env)


def file_absent(path: Path, name: Optional[str] = None):
    log = LOG.getChild("file_absent")
    if name is None:
        name = fmt(path)
    if path.exists():
        log.info(f"[holup]Removing {name}...[/holup]", path=path)
        rmtree(path)
    else:
        log.info(f"[yeah]{name} already absent.[/yeah]", path=path)


def dir_present(path: Path, desc: Optional[str] = None):
    log = LOG.getChild("dir_present")
    if desc is None:
        desc = fmt(path)
    if path.exists():
        if path.is_dir():
            log.debug(
                f"[yeah]{desc} directory already exists.[/yeah]", path=path
            )
        else:
            raise RuntimeError(f"{path} exists and is NOT a directory")
    else:
        log.info(f"[holup]Creating {desc} directory...[/holup]", path=path)
        os.makedirs(path)
