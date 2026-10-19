"""schemdraw helpers for bench schematics.

    from fzgen import schematic as sch
    sch.setup()
    with schemdraw.Drawing(file=out, show=False) as d:
        pm = sch.promicro([("D2", "right", "1/2"), ("GND", "bottom", None)])
        d += pm.anchor("D2").at(...)

Pin names and numbers come from the same TOP/BOTTOM rows fzgen places on the
breadboard, so a pin that is not on the board fails here too.
"""

import schemdraw
import schemdraw.elements as elm

from . import promicro as _pm

# Box geometry shared by every IC in a bench schematic.
IC = {"edgepadW": 0.8, "edgepadH": 0.6, "pinspacing": 1.8, "leadlen": 0.8}

# Schematic name -> board silkscreen name; the number outside the box is the
# Arduino pin. Power pins carry no number.
_DIGITAL = (*range(2, 11), 14, 15, 16)
_NAMES = {"RX0": "RX", "TX0": "TX", **{f"D{n}": str(n) for n in _DIGITAL}}
_NUMBERS = {"RX0": "0", "TX0": "1", **{f"D{n}": str(n) for n in _DIGITAL}}


def setup():
    """SVG backend, text as <path>: the viewer's font no longer decides whether
    a pin label lands on the box edge."""
    schemdraw.use("svg")
    schemdraw.svgconfig.text = "path"


def terminal(drawing, label, loc):
    """Open dot with a label: a header pin or socket contact off the drawing."""
    drawing += elm.Dot(open=True).label(label, loc=loc, ofst=0.25)


def promicro(pins, label="Pro Micro\nATmega32U4", **ic):
    """Pro Micro box with only the given pins: (name, side, slot or None).

    name is RX0/TX0, D2..D16, A0..A3, VCC, RAW, GND or RST; it must exist on the
    board (fzgen.promicro TOP/BOTTOM). ic overrides IC, e.g. edgepadW=2.5 when
    the label is wider than the box schemdraw sizes for the pins."""
    out = []
    for name, side, slot in pins:
        silk = _NAMES.get(name, name)
        if silk not in _pm.TOP + _pm.BOTTOM:
            raise ValueError(f"Pro Micro has no pin {name}")
        out.append(elm.IcPin(name=name, pin=_NUMBERS.get(name), side=side, slot=slot))
    return elm.Ic(pins=out, **{**IC, **ic}).label(label, loc="center", fontsize=10)
