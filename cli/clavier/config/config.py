from __future__ import annotations
from collections import namedtuple
from typing import (
    Optional,
    Any,
    Union,
    Iterable,
    Sequence,
)
import re
import os
from functools import reduce
from sortedcontainers import SortedDict

from .key import Key
from .scope import ReadScope
from .changeset import Changeset

class Config:
    ENV_VAR_NAME_SUB_RE = re.compile(r"[^A-Z0-9]+")

    Update = namedtuple("Update", "changes meta")

    class Env:
        @classmethod
        def __contains__(cls, key):
            return Key(key).env_name in os.environ

        @classmethod
        def __getitem__(cls, key):
            return os.environ[Key(key).env_name]

    @classmethod
    def env_has(cls, key) -> bool:
        return Key(key).env_name in os.environ

    @classmethod
    def env_get(cls, key):
        return os.environ[Key(key).env_name]

    def __init__(self):
        self._view = SortedDict()
        self._updates = []

    def configure(self, *prefix, **meta) -> Changeset:
        return Changeset(config=self, prefix=prefix, meta=meta)

    def __contains__(self, key):
        return Key(key) in self._view

    def __getitem__(self, key):
        key = Key(key)
        if self.env_has(key):
            return self.env_get(key)
        if key in self._view:
            return self._view[key]
        for k in self._view:
            if key in k.scopes():
                return ReadScope(base=self, key=key)
        raise KeyError(f"Config has no key or scope {key}")
    __getattr__ = __getitem__

    def __iter__(self):
        return iter(self._view)

    def update(self, changes, meta) -> None:
        self._view.update(changes)
        self._updates.insert(0, self.Update({**changes}, {**meta}))

    def to_dict(self):
        return {**self._view}
