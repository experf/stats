from typing import *

from nansi.proper import Proper, Prop

class A(Proper):
    _dest = Prop(Optional[str])

    @property
    def dest(self):
        if dest := A._dest.__get__(self):
            return dest
        return "default"

a = A(_dest="d1")

print(a.dest)

a2 = A()
print(a2.dest)

print(a2.__dict__)
