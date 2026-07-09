"""Tests del informe REPORTE_E1-A02_CRYPTOGRAPHIC_FAILURES_SMARTCSET.md.

Este informe quedó en estado PARCIAL (⚠️, no ✅): de los 3 hallazgos,
solo el de TLS hacia la base de datos tiene infraestructura de código
lista (aunque inactiva por defecto, a la espera de que la Oficina TI del
SENA habilite ``ssl=on`` en PostgreSQL). Los otros dos (cifrado en reposo
de ``documento_identidad`` y HTTPS forzado) están bloqueados/diferidos.

Premisa que SÍ se puede verificar en código (informe §hallazgo 2):

1. Existe la constante ``DB_SSLMODE``, leída desde ``.env`` con valor
   por defecto vacío (``''``), definida en ``src/core/config.php``.
2. ``src/core/Db.php`` solo agrega ``;sslmode=...`` al DSN de PDO si
   ``DB_SSLMODE`` no está vacío. Es decir: con el valor por defecto
   (vacío), el DSN NO cambia respecto al comportamiento anterior a E1-A02
   (sin esto, activar la constante sin cuidado podría romper la conexión
   en entornos sin TLS configurado en PostgreSQL).
3. ``.env.example`` documenta la variable ``DB_SSLMODE`` (vacía por
   defecto) para que cualquier instalación nueva sepa que existe.

No se verifica aquí ninguna conexión TLS real: eso depende de que la
Oficina TI del SENA habilite TLS en PostgreSQL (E8), fuera del alcance
de esta suite.

Nota (2026-07-09): rutas actualizadas de ``src/core/`` a
``backend/core/`` (ver AGENTS.md "Nota de rutas") — el archivo llevaba
desactualizado desde esa reorganización, con las 2 primeras
verificaciones fallando con FileNotFoundError sin que nadie lo
notara. El estado de TLS BD en sí mismo también avanzó desde que se
escribió el informe original (ver Bug 13/17 en CLAUDE.md: TLS BD ya
está activo en el servidor institucional, no solo "código listo en
espera de Oficina TI") — actualizar REPORTE_E1-A02 si se retoma ese
informe formalmente.
"""

from __future__ import annotations

import unittest

from common import PROJECT_ROOT


class TestE1A02CryptographicFailures(unittest.TestCase):
    """Verifica la infraestructura de código para TLS hacia la BD."""

    def test_db_sslmode_definida_con_default_vacio(self) -> None:
        """config.php debe definir DB_SSLMODE con default vacío."""
        archivo = PROJECT_ROOT / "backend" / "core" / "config.php"
        codigo = archivo.read_text(encoding="utf-8")

        self.assertIn("DB_SSLMODE", codigo)
        self.assertIn(
            "EnvLoader::get('DB_SSLMODE', '')",
            codigo,
            "DB_SSLMODE debería tener default '' (vacío) para no "
            "cambiar el comportamiento de conexión en instalaciones "
            "donde PostgreSQL no tiene TLS habilitado",
        )

    def test_db_php_solo_agrega_sslmode_si_no_esta_vacio(self) -> None:
        """Db.php debe agregar sslmode al DSN solo si DB_SSLMODE != ''."""
        archivo = PROJECT_ROOT / "backend" / "core" / "Db.php"
        codigo = archivo.read_text(encoding="utf-8")

        self.assertIn("DB_SSLMODE", codigo)
        self.assertIn("sslmode", codigo)
        # La condición debe comparar contra cadena vacía antes de
        # modificar el DSN; de lo contrario, un DB_SSLMODE vacío
        # generaría un DSN inválido como "...;sslmode=".
        self.assertIn("!== ''", codigo)

    def test_env_example_documenta_db_sslmode(self) -> None:
        """.env.example debe listar DB_SSLMODE para nuevas instalaciones."""
        archivo = PROJECT_ROOT / ".env.example"
        contenido = archivo.read_text(encoding="utf-8")

        self.assertIn("DB_SSLMODE", contenido)


if __name__ == "__main__":
    unittest.main()
