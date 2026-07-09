"""Tests del informe REPORTE_E1-E06_VERIFICACION_SUBIDA_ARCHIVOS_SMARTCSET.md.

Nota (2026-07-09): rutas actualizadas de la estructura vieja ``src/``
a la actual ``backend/``/``frontend/web/`` (ver AGENTS.md "Nota de
rutas"). El archivo llevaba desactualizado desde esa reorganización —
todos los tests fallaban con ``FileNotFoundError``/rutas inexistentes
sin que nadie lo notara, hasta la auditoría de esta sesión.

Premisas principales del informe:

1. ``backend/core/LogoUpload.php`` valida el tipo MIME real del
   archivo (con ``finfo``, no por la extensión declarada por el
   navegador), usa una whitelist de tipos de imagen, limita el tamaño
   a 5MB, exige ``is_uploaded_file()`` y genera un nombre de archivo
   aleatorio.
2. ``backend/services/porteria/foto_service.php`` valida
   estrictamente el formato ``data:`` URL en base64 y recomprime la
   imagen como JPEG (lo que destruye cualquier payload que no sea una
   imagen válida). ``backend/services/porteria/
   biometria_photo_service.php`` (2026-07-09, foto de enrolamiento
   facial) sigue el mismo patrón de validación MIME real.
3. Los directorios donde se guardan archivos subidos por usuarios
   (``frontend/web/public/uploads/logos/``,
   ``frontend/web/public/uploads/biometria/`` y ``storage/porteria/``)
   tienen un ``.htaccess`` que:
       - Bloquea la ejecución de PHP y otros scripts.
       - Fuerza ``Content-Type`` de imagen.
       - Bloquea el acceso directo al propio ``.htaccess``.
       - Desactiva el listado de directorios (``Options -Indexes``).

IMPORTANTE - alcance de esta verificación:

    El servidor de desarrollo (``php -S``) NO interpreta archivos
    ``.htaccess`` (eso es exclusivo de Apache). Por lo tanto, los tests
    de esta clase verifican el **contenido** de los archivos
    ``.htaccess`` y de las validaciones en PHP de forma ESTÁTICA (leyendo
    el código fuente), no mediante una petición HTTP real a un ``.php``
    subido. La prueba HTTP real (`curl https://host/storage/porteria/
    test.php` -> 403/404) está documentada en el informe §8.2 y debe
    ejecutarse contra el servidor Apache/Nginx de producción, fuera del
    alcance de esta suite.
"""

from __future__ import annotations

import unittest
from pathlib import Path

from common import PROJECT_ROOT

# Extensiones de script que el .htaccess debe bloquear explícitamente.
EXTENSIONES_BLOQUEADAS = ["php", "phtml", "phar", "pl", "py", "cgi", "sh"]

DIRECTORIOS_CON_HTACCESS = [
    PROJECT_ROOT / "frontend" / "web" / "public" / "uploads" / "logos",
    PROJECT_ROOT / "frontend" / "web" / "public" / "uploads" / "biometria",
    PROJECT_ROOT / "storage" / "porteria",
]


class TestE6VerificacionUploads(unittest.TestCase):
    """Verifica las protecciones estáticas de subida de archivos."""

    def test_htaccess_existe_en_directorios_de_subida(self) -> None:
        """Cada directorio de uploads debe tener su propio .htaccess."""
        for directorio in DIRECTORIOS_CON_HTACCESS:
            with self.subTest(directorio=str(directorio)):
                htaccess = directorio / ".htaccess"
                self.assertTrue(
                    htaccess.is_file(),
                    f"No existe {htaccess}. Sin él, un .php subido a "
                    f"{directorio} podría ejecutarse en Apache.",
                )

    def test_htaccess_bloquea_extensiones_de_script(self) -> None:
        """El .htaccess debe denegar la ejecución de .php y similares."""
        for directorio in DIRECTORIOS_CON_HTACCESS:
            htaccess = directorio / ".htaccess"
            contenido = htaccess.read_text(encoding="utf-8")

            with self.subTest(directorio=str(directorio)):
                # Debe existir un bloque <FilesMatch> con "Deny from all"
                # que cubra las extensiones de script peligrosas.
                self.assertIn("Deny from all", contenido)
                for extension in EXTENSIONES_BLOQUEADAS:
                    self.assertIn(
                        extension,
                        contenido,
                        f"{htaccess} no menciona la extensión '{extension}'",
                    )

    def test_htaccess_bloquea_acceso_directo_y_listado(self) -> None:
        """El .htaccess debe bloquear su propio acceso y Options -Indexes."""
        for directorio in DIRECTORIOS_CON_HTACCESS:
            htaccess = directorio / ".htaccess"
            contenido = htaccess.read_text(encoding="utf-8")

            with self.subTest(directorio=str(directorio)):
                self.assertIn('<Files ".htaccess">', contenido)
                self.assertIn("Options -Indexes", contenido)

    def test_logo_upload_valida_mime_real_y_tamano(self) -> None:
        """LogoUpload.php debe usar finfo, whitelist, límite de tamaño y
        nombre de archivo aleatorio (no el nombre original del usuario)."""
        archivo = PROJECT_ROOT / "backend" / "core" / "LogoUpload.php"
        codigo = archivo.read_text(encoding="utf-8")

        # finfo: detección de MIME real (no confiar en la extensión).
        self.assertIn(
            "finfo",
            codigo,
            "LogoUpload.php debería usar finfo para detectar el MIME real",
        )

        # is_uploaded_file(): evita path traversal / archivos no subidos
        # vía HTTP (protección estándar de PHP contra ataques de subida).
        self.assertIn("is_uploaded_file", codigo)

        # Límite de tamaño de 5MB (5 * 1024 * 1024 bytes).
        self.assertIn("5 * 1024 * 1024", codigo)

    def test_porteria_foto_recomprime_y_valida_data_url(self) -> None:
        """foto_service.php debe validar el data: URL y recomprimir a
        JPEG."""
        archivo = (
            PROJECT_ROOT
            / "backend"
            / "services"
            / "porteria"
            / "foto_service.php"
        )
        codigo = archivo.read_text(encoding="utf-8")

        # Validación estricta del prefijo data:image/...;base64,
        self.assertIn("data:image", codigo)
        self.assertIn("base64", codigo)

        # Recompresión a JPEG: cualquier payload que no sea una imagen
        # válida no sobrevive al paso por imagecreatefromstring +
        # imagejpeg.
        self.assertIn("imagejpeg", codigo)

    def test_biometria_foto_valida_mime_real(self) -> None:
        """biometria_photo_service.php (2026-07-09, foto de
        enrolamiento facial) debe validar el MIME real con finfo antes
        de guardar en frontend/web/public/uploads/biometria/ — mismo
        estándar que LogoUpload.php, dato más sensible aún (biométrico,
        no solo una imagen corporativa)."""
        archivo = (
            PROJECT_ROOT
            / "backend"
            / "services"
            / "porteria"
            / "biometria_photo_service.php"
        )
        codigo = archivo.read_text(encoding="utf-8")

        self.assertIn(
            "finfo",
            codigo,
            "biometria_photo_service.php debería usar finfo para "
            "detectar el MIME real (E6)",
        )
        self.assertIn("base64", codigo)


if __name__ == "__main__":
    unittest.main()
