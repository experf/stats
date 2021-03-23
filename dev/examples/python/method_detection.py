#!/usr/bin/env python

import inspect
from functools import wraps

def f(x):
    pass

class A:
    def f(self, x):
        pass


assert not inspect.ismethod(f)
assert not inspect.ismethod(A.f)
assert inspect.ismethod(A().f)

def is_unbound_method_of(fn, instance):
    fn = inspect.unwrap(fn)
    return (
        hasattr(fn, "__name__") and
        hasattr(instance, "__class__") and
        hasattr(instance.__class__, fn.__name__) and
        inspect.isfunction(getattr(instance.__class__, fn.__name__)) and
        inspect.unwrap(getattr(instance.__class__, fn.__name__)) is fn
    )

def inject_first(fn):
    value = "hey"
    @wraps(fn)
    def wrapper(*args, **kwds):
        print(f"fn: {repr(fn)}")
        print(f"args: {repr(args)}")

        if len(args) > 0 and is_unbound_method_of(fn, args[0]):
            print(f"INJECT instance method call")
            return fn(args[0], value, *args[1:], **kwds)
        print(f"INJECT function call")
        return fn(value, *args, **kwds)
    return wrapper

class B:
    @inject_first
    def f(self, *args, **kwds):
        print(f"args: {repr(args)}")
        print(f"kwds: {repr(kwds)}")

    def g(self):
        pass


instance = B()
fn = inspect.unwrap(B.f)
assert hasattr(fn, "__name__")
assert hasattr(instance, "__class__")
assert hasattr(instance.__class__, fn.__name__)
assert inspect.unwrap(getattr(instance.__class__, fn.__name__)) is fn

instance.f(1, 2, z=3)