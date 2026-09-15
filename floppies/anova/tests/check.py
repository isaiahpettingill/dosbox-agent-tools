"""Check actual DOS output against independently calculated fixtures."""
import math
import re
from pathlib import Path


def output(name):
    return Path(f"build/{name}.out").read_text(errors="replace")


def number(value):
    return float(value.replace("D", "E"))


def check_case(name, between, within, total, f_stat):
    text = output(name)
    assert "ERROR:" not in text, text
    for label, expected in (("BETWEEN", between), ("WITHIN", within),
                            ("TOTAL", total)):
        match = re.search(rf"^\s*{label}\s+(\d+)\s+([^\r\n]+)",
                          text, re.MULTILINE)
        assert match, (name, label, text)
        actual = [int(match[1])] + [number(v) for v in match[2].split()]
        assert len(actual) == len(expected), (name, label, actual)
        for a, e in zip(actual, expected):
            assert math.isclose(a, e, rel_tol=1e-8, abs_tol=1e-9), (
                name, label, actual, expected)
    match = re.search(r"F STATISTIC:\s+(\S+)", text)
    assert match and math.isclose(number(match[1]), f_stat, rel_tol=1e-8)


check_case("known", (2, 24, 12), (6, 6, 1), (8, 30), 12)
check_case("unequal", (1, 4.8, 4.8), (3, 10, 10 / 3), (4, 14.8), 1.44)
assert "F UNDEFINED: zero within-group variance." in output("zero")
assert "ERROR: group count" in output("invalid")
assert "ERROR: need positive within-group degrees" in output("singleton")
assert "ERROR: expected number" in output("truncated")
print("ANOVA: all 6 compiled-DOS output checks passed")
