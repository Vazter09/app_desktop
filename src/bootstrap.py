"""
Auto-arranque del entorno virtual — para que `python main.py` sea el
único comando que hay que recordar, sin activar nada a mano.

100% librería estándar (os, sys, subprocess, venv) — se ejecuta ANTES de
cualquier import que necesite `opencv-python` (cv2), así que este módulo
en particular no puede depender de nada que no venga con Python.

Layout:
  app_desktop/requirements.txt
  app_desktop/runtime/.venv/
  app_desktop/src/main.py   ← este proceso

Si el venv no existe, lo crea e instala requirements la primera vez;
si ya existe, re-ejecuta el proceso con ese intérprete.
"""
from __future__ import annotations

import hashlib
import os
import subprocess
import sys

_ENV_FLAG = "SMARTCSET_VENV_ACTIVE"
_REQUIREMENTS_HASH_FILE = ".requirements.hash"


def _same_python(left: str, right: str) -> bool:
    return os.path.normcase(os.path.abspath(left)) == os.path.normcase(
        os.path.abspath(right)
    )


def _is_venv_interpreter(exe: str, venv_dir: str, is_windows: bool) -> bool:
    if is_windows:
        scripts = os.path.join(venv_dir, "Scripts")
        if (
            _same_python(exe, os.path.join(scripts, "python.exe"))
            or _same_python(exe, os.path.join(scripts, "pythonw.exe"))
        ):
            return True
        exe_norm = os.path.normcase(os.path.abspath(exe))
        scripts_norm = os.path.normcase(os.path.abspath(scripts))
        base = os.path.basename(exe_norm)
        return exe_norm.startswith(scripts_norm + os.sep) and base in {
            "python.exe",
            "pythonw.exe",
        }
    return _same_python(exe, os.path.join(venv_dir, "bin", "python3"))


def _reexec_launcher(venv_dir: str, is_windows: bool) -> str:
    """pythonw.exe en Windows evita la ventana negra de consola (solo GUI)."""
    if is_windows:
        scripts = os.path.join(venv_dir, "Scripts")
        pythonw = os.path.join(scripts, "pythonw.exe")
        if os.path.isfile(pythonw):
            return pythonw
        return os.path.join(scripts, "python.exe")
    return os.path.join(venv_dir, "bin", "python3")


def ensure_venv() -> None:
    """Garantiza que el proceso corre con el Python de runtime/.venv.

    Debe llamarse ANTES de importar cualquier módulo que use `cv2`.
    Empaquetado (PyInstaller): no-op — las deps ya van dentro del .exe.
    """
    if getattr(sys, "frozen", False):
        return

    if os.environ.get(_ENV_FLAG) == "1":
        return

    src_dir = os.path.dirname(os.path.abspath(__file__))
    module_root = os.path.dirname(src_dir)
    runtime_dir = os.path.join(module_root, "runtime")
    os.makedirs(runtime_dir, exist_ok=True)

    venv_dir = os.path.join(runtime_dir, ".venv")
    is_windows = os.name == "nt"
    venv_python = (
        os.path.join(venv_dir, "Scripts", "python.exe")
        if is_windows
        else os.path.join(venv_dir, "bin", "python3")
    )

    if _is_venv_interpreter(sys.executable, venv_dir, is_windows):
        os.environ[_ENV_FLAG] = "1"
        return

    requirements_file = os.path.join(module_root, "requirements.txt")
    hash_file = os.path.join(runtime_dir, _REQUIREMENTS_HASH_FILE)

    try:
        with open(requirements_file, "rb") as f:
            requirements_hash = hashlib.md5(f.read()).hexdigest()
    except FileNotFoundError:
        requirements_hash = ""

    requirements_changed = False
    if os.path.isfile(hash_file):
        try:
            with open(hash_file, "r", encoding="utf-8") as f:
                old_hash = f.read().strip()
                requirements_changed = old_hash != requirements_hash
        except Exception:
            requirements_changed = True

    if not os.path.isfile(venv_python) or requirements_changed:
        if not os.path.isfile(venv_python):
            print("Primer arranque: creando entorno virtual (runtime/.venv)...")
            import venv as venv_module

            venv_module.create(venv_dir, with_pip=True)
        elif requirements_changed:
            print("Dependencias actualizadas: reinstalando...")

        venv_pip = (
            os.path.join(venv_dir, "Scripts", "pip.exe")
            if is_windows
            else os.path.join(venv_dir, "bin", "pip")
        )

        print("Instalando dependencias desde requirements.txt...")
        subprocess.run(
            [venv_pip, "install", "--quiet", "-r", requirements_file],
            check=True,
        )

        try:
            with open(hash_file, "w", encoding="utf-8") as f:
                f.write(requirements_hash)
        except Exception:
            pass

        print("Entorno listo.")

    env = os.environ.copy()
    env[_ENV_FLAG] = "1"
    script = os.path.abspath(sys.argv[0])
    launcher = _reexec_launcher(venv_dir, is_windows)
    args = [launcher, script, *sys.argv[1:]]

    if is_windows:
        # cwd=src_dir para que imports relativos (ui, motor, …) resuelvan.
        subprocess.Popen(args, env=env, cwd=src_dir)
        os._exit(0)

    os.execve(venv_python, args, env)
