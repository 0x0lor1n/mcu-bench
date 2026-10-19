"""SparkFun Pro Micro 5 V/16 MHz (DEV-12640, ATmega32U4).

Header rows as printed on the silkscreen, USB to the left, component side up.
"""

# The two 12-pin rows, left to right.
TOP = ["RAW", "GND", "RST", "VCC", "A3", "A2", "A1", "A0", "15", "14", "16", "10"]
BOTTOM = ["TX", "RX", "GND", "GND", "2", "3", "4", "5", "6", "7", "8", "9"]

# Schematic signal name -> silkscreen label. The Arduino pin number is the
# label for every digital pin; RX/TX are pins 0/1. Power pins have no number.
_DIGITAL = (*range(2, 11), 14, 15, 16)
SILK = {"RX0": "RX", "TX0": "TX", **{f"D{n}": str(n) for n in _DIGITAL}}
NUMBER = {"RX0": "0", "TX0": "1", **{f"D{n}": str(n) for n in _DIGITAL}}


def silk(name):
    """Silkscreen label for a schematic name (D2, RX0, GND, A0, ...)."""
    label = SILK.get(name, name)
    if label not in TOP + BOTTOM:
        raise ValueError(f"Pro Micro has no pin {name}")
    return label
