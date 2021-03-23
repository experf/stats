_values = {}

def __getattr__(name):
    global _values
    print(f"GET {name}")
    return _values[name]

def __setattr__(name, value):
    global _values
    print(f"SET {name} <- {repr(value)}")
    _values[name] = value

