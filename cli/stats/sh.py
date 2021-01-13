from typing import *
import logging
import os
from os.path import isabs, basename
import subprocess
from pathlib import Path
import json

from .io import OUT, ERR, sh

LOG = logging.getLogger(__name__)

TOptValue = Union[bool, str, int, float]
TOpts = Dict[str, Union[TOptValue, List[TOptValue]]]
TOptsStyle = Literal["=", " "]

DEFAULT_OPTS_STYLE = "="
DEFAULT_OPTS_SORT = True


def iter_opt(flag, value, style, is_short):
    if is_short or style == " ":
        yield flag
        yield str(value)
    else:
        yield f"{flag}={value}"


def flat_opts(
    opts: Optional[TOpts],
    *,
    style: TOptsStyle = DEFAULT_OPTS_STYLE,
    sort: bool = DEFAULT_OPTS_SORT,
):
    if opts is None:
        return
    if sort:
        items = sorted(opts.items())
    else:
        items = opts.items()
    for name, value in items:
        if value is None:
            continue
        is_short = len(name) == 1
        flag = f"-{name}" if is_short else f"--{name}"
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


def get(*args, chdir=None, fmt=None, encoding="utf-8", **opts):
    if isinstance(chdir, Path):
        chdir = str(chdir)

    cmd = flatten_args(args)

    LOG.getChild("get").info(
        "Getting command output...",
        cmd=cmd,
        chdir=chdir,
        fmt=fmt,
        encoding=encoding,
        **opts
    )
    # https://docs.python.org/3.8/library/subprocess.html#subprocess.run
    output = subprocess.check_output(
        cmd, encoding=encoding, cwd=chdir, **opts
    )

    if fmt == "json":
        return json.loads(output)
    else:
        return output


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
    LOG.getChild("exec").info(
        "Replacing current process with command...",
        cmd=cmd,
        env=env,
        chdir=chdir,
    )
    if chdir is not None:
        os.chdir(chdir)
    if env is None:
        if isabs(exe):
            os.execv(proc_name, cmd)
        else:
            os.execvp(proc_name, cmd)
    else:
        if isabs(exe):
            os.execve(proc_name, cmd, env)
        else:
            os.execvpe(proc_name, cmd, env)
