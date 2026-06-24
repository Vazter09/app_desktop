"""Tests del informe REPORTE_E1-E07_CORRECCION_SETUP_SMARTCSET.md.

Premisas principales del informe:

1. ``database/setup_smartcset.sh`` incluye en su arreglo ``FUNCS`` (las
   funciones PL/pgSQL que se despliegan en una instalación nueva) los
   tres archivos que antes faltaban:
       - acceso/usuarios/fun_validar_login.sql
       - acceso/usuarios/fun_validar_correo.sql
       - acceso/usuarios/fun_validar_usuario.sql
2. ``acceso/menus/fun_tab_menu_usuarios.sql`` (legacy) se excluyó
   DELIBERADAMENTE de ``FUNCS`` porque sobreescribiría versiones más
   seguras de ``fun_insert_menu_usuarios`` /
   ``fun_delete_perfil_usuario`` ya desplegadas. Este test verifica que
   siga sin estar en ``FUNCS`` (si alguien lo agrega "para completar la
   lista", reintroduciría una regresión de seguridad).
3. Las 3 funciones agregadas (`fun_validar_login`, `fun_validar_correo`,
   `fun_validar_usuario`) existen realmente en la base de datos de
   desarrollo, es decir, el `CREATE FUNCTION` no solo está en el script
   sino que se ejecutó sin error de sintaxis.

Estos tests son principalmente estáticos (leen el script de instalación
como texto). El test de existencia en BD requiere ``psql`` y la base de
datos de desarrollo configurada en ``.env``; si ``psql`` no está
disponible, ese test se salta con un mensaje explicativo.
"""

from __future__ import annotations

import unittest

from common import PROJECT_ROOT, run_psql

SETUP_SCRIPT = PROJECT_ROOT / "database" / "setup_smartcset.sh"

# Las 3 funciones que el informe E7 agregó al arreglo FUNCS.
FUNCIONES_AGREGADAS = [
    "acceso/usuarios/fun_validar_login.sql",
    "acceso/usuarios/fun_validar_correo.sql",
    "acceso/usuarios/fun_validar_usuario.sql",
]

# Archivo legacy que NO debe estar en FUNCS (ver informe §2, decisión
# explícita de exclusión por riesgo de regresión de seguridad).
FUNCION_LEGACY_EXCLUIDA = "acceso/menus/fun_tab_menu_usuarios.sql"


class TestE7CorreccionSetup(unittest.TestCase):
    """Verifica el contenido del arreglo FUNCS de setup_smartcset.sh."""

    @classmethod
    def setUpClass(cls) -> None:
        if not SETUP_SCRIPT.is_file():
            raise unittest.SkipTest(f"No se encuentra {SETUP_SCRIPT}")
        cls.contenido_setup = SETUP_SCRIPT.read_text(encoding="utf-8")

    def test_funciones_agregadas_estan_en_funcs(self) -> None:
        """Las 3 funciones del informe deben estar listadas en FUNCS."""
        for funcion in FUNCIONES_AGREGADAS:
            with self.subTest(funcion=funcion):
                self.assertIn(
                    funcion,
                    self.contenido_setup,
                    f"{funcion} no está en el arreglo FUNCS de "
                    f"{SETUP_SCRIPT.name}; una instalación nueva no la "
                    "desplegaría",
                )

    def test_funcion_legacy_sigue_excluida(self) -> None:
        """fun_tab_menu_usuarios.sql NO debe estar en FUNCS.

        Si este test falla porque alguien lo agregó de nuevo, revisar
        el informe E7 §2: ese archivo legacy sobreescribe versiones más
        seguras de fun_insert_menu_usuarios / fun_delete_perfil_usuario.
        """
        self.assertNotIn(
            FUNCION_LEGACY_EXCLUIDA,
            self.contenido_setup,
            f"{FUNCION_LEGACY_EXCLUIDA} fue agregado de nuevo a FUNCS; "
            "esto reintroduce una regresión de seguridad (ver informe "
            "E7 §2)",
        )

    def test_funciones_agregadas_existen_en_bd(self) -> None:
        """Las 3 funciones deben existir realmente en la BD de desarrollo."""
        try:
            salida = run_psql(
                "SELECT proname FROM pg_proc WHERE proname IN "
                "('fun_validar_login', 'fun_validar_correo', "
                "'fun_validar_usuario') ORDER BY proname;"
            )
        except RuntimeError as exc:
            raise unittest.SkipTest(str(exc))

        funciones_en_bd = set(salida.splitlines())
        self.assertEqual(
            funciones_en_bd,
            {"fun_validar_correo", "fun_validar_login", "fun_validar_usuario"},
            "No se encontraron las 3 funciones esperadas en pg_proc; "
            "¿se ejecutó setup_smartcset.sh contra esta BD?",
        )


if __name__ == "__main__":
    unittest.main()
