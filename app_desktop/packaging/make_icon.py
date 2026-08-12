"""Genera packaging/smartcset_porteria.ico desde assets/img/img-ejecutable.png."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PNG = ROOT / "src" / "assets" / "img" / "img-ejecutable.png"
ICO = Path(__file__).resolve().parent / "smartcset_porteria.ico"


def main() -> None:
    im = Image.open(PNG).convert("RGBA")
    sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    im.save(ICO, format="ICO", sizes=sizes)
    print(f"ICO OK: {ICO}")


if __name__ == "__main__":
    main()
