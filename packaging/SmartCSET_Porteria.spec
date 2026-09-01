# -*- mode: python ; coding: utf-8 -*-
"""PyInstaller onefile — un solo .exe, sin carpeta _internal ni .py."""

from pathlib import Path

block_cipher = None

ROOT = Path(SPECPATH).resolve().parent
SRC_DIR = ROOT / "src"
PACK = ROOT / "packaging"
ASSETS = SRC_DIR / "assets" / "img"
MODELS = SRC_DIR / "motor" / "models"
ICON = PACK / "smartcset_porteria.ico"
HOOK = PACK / "pyi_runtime_hook_config.py"

datas = [
    (str(ASSETS / "logo-sena.png"), "assets/img"),
    (str(ASSETS / "huella.png"), "assets/img"),
    (str(ASSETS / "img-ejecutable.png"), "assets/img"),
    (str(MODELS / "face_detection_yunet_2023mar.onnx"), "motor/models"),
    (str(MODELS / "face_recognition_sface_2021dec.onnx"), "motor/models"),
    (str(PACK / "app_config.porteria.json"), "."),
]

a = Analysis(
    [str(SRC_DIR / "main.py")],
    pathex=[str(SRC_DIR)],
    binaries=[],
    datas=datas,
    hiddenimports=[
        "PIL._tkinter_finder",
        "cv2",
        "numpy",
        "tzdata",
        "zoneinfo",
        "tkinter",
        "tkinter.messagebox",
        "tkinter.ttk",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[str(HOOK)] if HOOK.is_file() else [],
    excludes=[
        "tests",
        "pytest",
        "unittest",
        "matplotlib",
        "pandas",
        "scipy",
        "sklearn",
        "IPython",
        "notebook",
        "jupyter",
        "pip",
        "wheel",
        "setuptools",
        "pydoc",
        "doctest",
        "xmlrpc",
        "test",
        "lib2to3",
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
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name="SmartCSET_Porteria",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=str(ICON) if ICON.is_file() else None,
)
