from stats.etc import find_map

def mapper(s: str) -> int:
    return len(s)

result = find_map(
    mapper,
    ["hey", "ho", "let's go"],
    nothing=[3, 2, 8]
)

print(f"result: {result}")
