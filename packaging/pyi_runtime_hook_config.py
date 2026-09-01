"""Al primer arranque del .exe, deja app_config.json junto al ejecutable.

No toca el codigo de porteria: corre antes de main.py. Si el archivo ya
existe, no lo pisa.
"""
from __future__ import annotations

import os
import sys


def _seed_app_config() -> None:
    if not getattr(sys, "frozen", False):
        return
    dest_dir = os.path.dirname(os.path.abspath(sys.executable))
    dest = os.path.join(dest_dir, "app_config.json")
    if os.path.isfile(dest):
        return
    meipass = getattr(sys, "_MEIPASS", "")
    src = os.path.join(meipass, "app_config.porteria.json")
    if not os.path.isfile(src):
        return
    try:
        with open(src, "rb") as fsrc, open(dest, "wb") as fdst:
            fdst.write(fsrc.read())
    except OSError:
        pass


_seed_app_config()
