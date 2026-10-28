"""SOIC-8 test clip, drawn as the DIP-8 its leads form across the centre gap.

Pins are named by the JEDEC 25xx SPI flash pinout, the chip the clip sits on.
"""

from .part import MM, GenPart, P, text

# Pin n is PINS[n - 1].
PINS = ["CS#", "DO", "WP#", "GND", "DI", "CLK", "HOLD#", "VCC"]


def conn(name):
    return f"connector{PINS.index(name)}"


def hole(name, col0):
    """Pins 1-4 on row E from col0, 8-5 on row F above them."""
    i = PINS.index(name)
    return f"pin{col0 + i}E" if i < 4 else f"pin{col0 + 7 - i}F"


def part(module_id, title="SOIC-8 clip"):
    w, h = 20 * MM, 10 * MM
    x0, y_bottom = w / 2 - 1.5 * P, h / 2 + 1.5 * P
    p = GenPart(
        module_id,
        title,
        "J",
        "test clip",
        "SOIC-8 test clip on a 25xx SPI flash, pin 1 bottom left.",
        w,
        h,
        "male",
        author="mcubench/fritzing/soic8clip.py",
        tag="mcu-bench",
    )
    p.art.append(f'<rect x="0" y="0" width="{w:.2f}" height="{h:.2f}" rx="2" fill="#2f5fb3"/>')
    p.art.append(f'<circle cx="{x0 - 4:.2f}" cy="{y_bottom - 7:.2f}" r="1.5" fill="#ffffff"/>')
    for i, name in enumerate(PINS):
        k = i if i < 4 else 7 - i
        x, y = x0 + k * P, y_bottom if i < 4 else y_bottom - 3 * P
        p.art.append(text(x, y + (-4 if i < 4 else 7), name, 2.6))
        p.pin(name, x, y, "L" if i < 4 else "R")
    return p


def files(module_id):
    return part(module_id).files()


def place(sk, module_id, title, col0):
    """Embed and plug all 8 pins, pin 1 in pin{col0}E."""
    clip = sk.embed(module_id, title, files(module_id))
    clip.place(conn("CS#"), sk.hole(hole("CS#", col0)))
    clip.z = 2.6
    for name in PINS:
        sk.plug(clip, conn(name), hole(name, col0))
    return clip
