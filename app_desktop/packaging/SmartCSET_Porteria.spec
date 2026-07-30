# -*- mode: python ; coding: utf-8 -*-
"""PyInstaller spec — solo app_desktop (portería)."""

from pathlib import Path

block_cipher = None

APP_DIR = Path(SPECPATH).resolve().parent / "app"
ASSETS = APP_DIR / "assets" / "img"
MODELS = APP_DIR / "motor" / "models"
ICON = Path(SPECPATH).resolve().parent / "packaging" / "smartcset_porteria.ico"

datas = [
    (str(ASSETS / "logo-sena.png"), "assets/img"),
    (str(ASSETS / "huella.png"), "assets/img"),
    (str(ASSETS / "img-ejecutable.png"), "assets/img"),
    (str(MODELS / "face_detection_yunet_2023mar.onnx"), "motor/models"),
    (str(MODELS / "face_recognition_sface_2021dec.onnx"), "motor/models"),
]

a = Analysis(
    [str(APP_DIR / "main.py")],
    pathex=[str(APP_DIR)],
    binaries=[],
    datas=datas,
    hiddenimports=[
        "PIL._tkinter_finder",
        "cv2",
        "numpy",
        "tzdata",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        "tests",
        "pytest",
        "unittest",
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="SmartCSET_Porteria",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=str(ICON) if ICON.is_file() else None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name="SmartCSET_Porteria",
)
