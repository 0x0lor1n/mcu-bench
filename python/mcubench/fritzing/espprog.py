"""Espressif ESP-Prog, wired from its 2.54 mm JTAG header.

The 2x5 header cannot go into a breadboard (both rows would share a strip),
so the board sits beside it and wires land on the header pins.
"""

import os
import re
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))

# JTAG header pin number by silkscreen name; 5, 7, 9 are GND too, 10 is NC.
JTAG = {"VDD": 1, "TMS": 2, "GND": 3, "TCK": 4, "TDO": 6, "TDI": 8}

# SPI signal as flashrom's ft2232_spi drives it -> JTAG name.
SPI = {"CS#": "TMS", "CLK": "TCK", "MOSI": "TDI", "MISO": "TDO"}

# vanepp's part: header pin n on the 0.1 in row is connector{7 + n}.
CONN = {name: f"connector{7 + n}" for name, n in JTAG.items()}


def silk(name):
    """JTAG header label for a schematic name (CS#, CLK, GND, TDI, ...)."""
    label = SPI.get(name, name)
    if label not in JTAG:
        raise ValueError(f"ESP-Prog JTAG header has no pin {name}")
    return label


def conn(name):
    return CONN[silk(name)]


def files(module_id):
    """vanepp's part with the given moduleId."""
    z = zipfile.ZipFile(os.path.join(HERE, "vendor/espressif-esp-prog.fzpz"))
    out = {}
    for n in z.namelist():
        data = z.read(n).decode("utf-8")
        if n.startswith("part."):
            data = re.sub(r'moduleId="[^"]+"', f'moduleId="{module_id}"', data, count=1)
            n = f"part.{module_id}.fzp"
        out[n] = data
    return out


def place(sk, module_id, title, at):
    """Embed with the GND pin (header pin 3) at scene point at."""
    ep = sk.embed(module_id, title, files(module_id))
    ep.place(CONN["GND"], at)
    ep.z = 2.6
    return ep
