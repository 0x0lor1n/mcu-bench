"""schemdraw helpers for bench schematics.

    from mcubench import schematic as sch
    sch.setup()
    with schemdraw.Drawing(file=out, show=False) as d:
        pm = sch.promicro([("D2", "right", "1/2"), ("GND", "bottom", None)])
        d += pm.anchor("D2").at(...)

Pin names and numbers come from mcubench.boards, the same map the breadboard
generator places, so a pin that is not on the board fails here too.
"""

import schemdraw
import schemdraw.elements as elm

from .boards import promicro as _pm

# Box geometry shared by every IC in a bench schematic.
IC = {"edgepadW": 0.8, "edgepadH": 0.6, "pinspacing": 1.8, "leadlen": 0.8}


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
    board (mcubench.boards.promicro). ic overrides IC, e.g. edgepadW=2.5 when
    the label is wider than the box schemdraw sizes for the pins."""
    out = []
    for name, side, slot in pins:
        _pm.silk(name)  # raises on a pin the board does not have
        out.append(elm.IcPin(name=name, pin=_pm.NUMBER.get(name), side=side, slot=slot))
    return elm.Ic(pins=out, **{**IC, **ic}).label(label, loc="center", fontsize=10)
