"""Auditoría de cumplimiento de TODAS las funciones PL/pgSQL de
SmartCSET contra los 5 Pilares Obligatorios y el Plan de Blindaje
MSPI (Documentacion para implementacion de MSPI/FASE 01_Blindaje
Técnico Inmediato/).

A diferencia de los demás archivos de esta carpeta (que verifican un
entregable puntual, p. ej. ``test_e3_rate_limiting.py``), esta suite
es transversal: recorre ``database/functions/`` completo (72+
archivos) y ``database/setup_smartcset.sh``, en vez de una lista fija
de funciones conocidas. El objetivo es que un archivo ``.sql`` nuevo
quede cubierto automáticamente sin tener que acordarse de agregarlo
a un test — exactamente el tipo de brecha que causó los Bugs 2, 6, 17
y 20 documentados en ``CLAUDE.md``.

Mapeo a Pilares + MSPI + Fase 1 (ver "PREMISAS PRINCIPALES" en
``CLAUDE.md``/``AGENTS.md``):

- **Pilar 4 (Estabilidad) + Bug 6/17:** ninguna función debe llamar
  ``smartcset_handle_sql_error()`` sin argumentos (crashea con "GET
  STACKED DIAGNOSTICS fuera del bloque EXCEPTION").
- **Pilar 4 (Estabilidad) + Bug 20:** ningún cambio de aridad debe
  dejar dos firmas de la misma función ``fun_*`` conviviendo en la
  BD real (``CREATE OR REPLACE`` con distinto número de argumentos no
  reemplaza, sobrecarga).
- **Pilar 2 (Congruencia) + Bug 2/4/17 + E7:** todo archivo de función
  en disco debe estar registrado en el arreglo ``FUNCS`` del
  instalador, o explícitamente documentado como excluido con su
  razón — nunca "se me olvidó agregarlo".
- **Pilar 5 (Seguridad Total) + E1-A03 (OWASP Injection) + MSPI Eje 8
  (desarrollo seguro):** ninguna función debe ejecutar SQL dinámico
  concatenado con ``||`` sin pasar por ``USING`` (parámetros
  vinculados) — guarda contra inyección SQL en ``EXECUTE``.
- **Pilar 4 (Estabilidad):** toda función de negocio (no triggers, no
  helpers de excepción) debe tener su propio bloque ``EXCEPTION`` con
  las 4 variables de diagnóstico documentadas en ``CLAUDE.md``.

Los tests estáticos (leen archivos como texto) corren siempre, sin
necesitar BD ni red. Los tests dinámicos (contra ``pg_proc`` real)
requieren ``psql`` y la BD configurada en ``.env``; si no están
disponibles, se saltan con un mensaje explícito (mismo patrón que el
resto de esta suite — no se mockea la base de datos, ver CLAUDE.md
"Lo que NO hacer").
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

from common import PROJECT_ROOT, run_psql

FUNCTIONS_DIR = PROJECT_ROOT / "database" / "functions"
SETUP_SCRIPT = PROJECT_ROOT / "database" / "setup_smartcset.sh"

# Patrón roto (Bug 6/17): la versión de 0 argumentos de
# smartcset_handle_sql_error() usa GET STACKED DIAGNOSTICS fuera del
# bloque EXCEPTION del subprograma que la llama — PostgreSQL lo
# prohíbe. Zero tolerancia a que se LLAME así. No se busca la cadena
# a secas: "DROP FUNCTION IF EXISTS smartcset_handle_sql_error()" es
# el retiro correcto de la firma vieja (ver _helpers/smartcset_raise
# .sql) y no debe marcarse como un hallazgo.
PATRON_ERROR_ROTO = re.compile(r"\bsmartcset_handle_sql_error\s*\(\s*\)")


def _lineas_de_llamada_rota(contenido: str) -> list[str]:
    """Líneas que invocan smartcset_handle_sql_error() sin argumentos,
    excluyendo el DROP FUNCTION IF EXISTS que retira correctamente esa
    firma vieja (patrón documentado en _helpers/smartcset_raise.sql)."""
    return [
        linea
        for linea in contenido.splitlines()
        if PATRON_ERROR_ROTO.search(linea)
        and "DROP FUNCTION" not in linea.upper()
    ]

# EXECUTE de SQL dinámico con concatenación de string (||) sin pasar
# por USING (parámetros vinculados) es el patrón clásico de inyección
# SQL en PL/pgSQL (E1-A03 / OWASP A03). "EXECUTE FUNCTION" (cláusula
# de CREATE TRIGGER, no SQL dinámico) se excluye explícitamente.
PATRON_EXECUTE_RIESGOSO = re.compile(
    r"EXECUTE\s+(?!FUNCTION\b)[^;]*\|\|[^;]*;",
    re.IGNORECASE,
)

LINEA_COMENTARIO = re.compile(r"^\s*--")

PATRON_CREATE_FUNCTION = re.compile(
    r"CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+"
    r"([a-zA-Z_][a-zA-Z0-9_]*)",
    re.IGNORECASE,
)

VARIABLES_DIAGNOSTICO = (
    "w_exc_state",
    "w_exc_msg",
    "w_exc_detail",
    "w_exc_hint",
)

# Prefijos/rutas cuyas funciones legítimamente NO llevan bloque
# EXCEPTION con el patrón de 4 variables: triggers simples
# (fun_trigger_*, documentados en CLAUDE.md como categoría aparte) y
# los helpers de excepción mismos (_helpers/smartcset_raise.sql define
# las primitivas, no las usa).
SIN_EXCEPTION_OBLIGATORIA = ("_helpers/", "fun_trigger_")

# Archivos con función PL/pgSQL que existen en el repo pero se
# excluyen deliberadamente del arreglo FUNCS de setup_smartcset.sh,
# con la razón documentada en CLAUDE.md ("Bugs conocidos / deuda
# técnica"). Si aparece un archivo nuevo en disco que no está aquí ni
# en FUNCS, el test de cobertura del instalador debe fallar — así no
# se repite el Bug 2 (función que existe pero nadie la despliega).
ARCHIVOS_EXCLUIDOS_DEL_INSTALADOR = {
    # Bug 2/E7: legacy, sobreescribiría versiones más seguras ya
    # desplegadas de fun_insert_menu_usuarios/fun_delete_perfil_usuario.
    "acceso/menus/fun_tab_menu_usuarios.sql",
    # Bug 2: descripción no coincide con la implementación real,
    # pendiente de análisis propio (fuera de alcance de E7).
    "acceso/menus/fun_delete_perfil_usuarios.sql",
    # Bug 4: carga de reportes Excel SENA, omisión intencional —
    # desplegar manualmente si el módulo de carga está activo.
    "carga/fun_crear_usuarios_instructores.sql",
    "carga/fun_proceso_df14a.sql",
    "carga/fun_proceso_df49 V.1.0.sql",
    "carga/fun_proceso_df49 V.1.1.sql",
    "carga/fun_proceso_fichas_creadas.sql",
    "carga/fun_proceso_juicios.sql",
    "carga/fun_proceso_matriculados.sql",
    "carga/fun_proceso_pe04 V.1.0.sql",
    "carga/fun_proceso_pe04 V.1.1 .sql",
    # E2 (cifrado en reposo): bloqueado, documento_identidad es la PK,
    # requiere rediseño de schema antes de poder cifrar.
    "config/fun_cifrar_documento.sql",
    "config/fun_descifrar_documento.sql",
    # Módulo "comité de retrasos / llamados de atención"
    # (pages/modulos/en_construccion/): sin integrar todavía.
    "porteria/novedades/fun_novedades_academicas.sql",
    "porteria/retrasos_comite/fun_actualizar_num_llamados.sql",
    "porteria/retrasos_comite/fun_obtener_centro_aprendiz.sql",
    "porteria/retrasos_comite/fun_obtener_limite_llamados.sql",
    "porteria/retrasos_comite/fun_sincronizar_comite_aprendiz.sql",
    "porteria/retrasos_comite/fun_verify_retardo_aprendiz v.1.1.sql",
    "porteria/retrasos_comite/fun_verify_retardo_aprendiz v.1.2.sql",
    "porteria/retrasos_comite/proc_recalcular_comites_por_centro.sql",
    "porteria/retrasos_comite/triggers.sql",
}


def _archivos_funciones() -> list[Path]:
    """Todos los ``.sql`` bajo ``database/functions/``, orden estable."""
    if not FUNCTIONS_DIR.is_dir():
        return []
    return sorted(FUNCTIONS_DIR.rglob("*.sql"))


def _ruta_relativa(archivo: Path) -> str:
    return archivo.relative_to(FUNCTIONS_DIR).as_posix()


def _sin_comentarios(texto: str) -> str:
    """Quita líneas ``-- comentario`` para no marcar SQL dinámico
    comentado (código muerto, no un riesgo real) como si fuera un
    hallazgo activo."""
    return "\n".join(
        linea
        for linea in texto.splitlines()
        if not LINEA_COMENTARIO.match(linea)
    )


class TestPatronManejoErroresPLpgSQL(unittest.TestCase):
    """Bug 6/17 (CLAUDE.md): cero tolerancia al handler de 0 args."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.archivos = _archivos_funciones()
        if not cls.archivos:
            raise unittest.SkipTest(
                f"No se encontraron archivos .sql en {FUNCTIONS_DIR}"
            )

    def test_ningun_archivo_usa_handler_sin_argumentos(self) -> None:
        """Ningún .sql debe invocar smartcset_handle_sql_error() sin
        argumentos — ese patrón crashea cualquier función que lo use
        en el primer error inesperado (Bug 6, reintroducido y vuelto
        a corregir en Bug 17)."""
        infractores = []
        for archivo in self.archivos:
            contenido = archivo.read_text(encoding="utf-8")
            if _lineas_de_llamada_rota(contenido):
                infractores.append(_ruta_relativa(archivo))

        self.assertEqual(
            infractores,
            [],
            "Archivos con smartcset_handle_sql_error() sin "
            f"argumentos (patrón roto, Bug 6/17): {infractores}",
        )

    def test_bd_no_tiene_funciones_con_patron_roto(self) -> None:
        """Verifica contra la BD real (no solo el código fuente) que
        ninguna función DESPLEGADA tenga el patrón roto — cubre el
        caso del Bug 17: el archivo fuente ya estaba corregido pero
        una migración posterior reintrodujo la versión rota en la BD
        real, y el código fuente por sí solo no lo habría detectado.
        """
        try:
            salida = run_psql(
                "SELECT proname FROM pg_proc WHERE prosrc LIKE "
                "'%smartcset_handle_sql_error()%' ORDER BY proname;"
            )
        except RuntimeError as exc:
            raise unittest.SkipTest(str(exc))

        funciones_rotas = [
            linea for linea in salida.splitlines() if linea.strip()
        ]
        self.assertEqual(
            funciones_rotas,
            [],
            "Funciones desplegadas en BD con el patrón de error roto "
            f"(Bug 6/17): {funciones_rotas}",
        )


class TestBloqueExceptionCompleto(unittest.TestCase):
    """Pilar 4 (Estabilidad): toda función de negocio REALMENTE
    DESPLEGADA (registrada en FUNCS, no un módulo WIP sin integrar)
    debe tener su propio bloque EXCEPTION con las 4 variables de
    diagnóstico. Los módulos en ARCHIVOS_EXCLUIDOS_DEL_INSTALADOR se
    excluyen aquí a propósito: quedan pendientes de revisión completa
    (incluido este patrón) el día que se activen, no antes — así el
    hallazgo de esta suite se queda sobre lo que sí corre en
    producción hoy, sin ruido de código todavía no integrado."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.archivos = [
            a
            for a in _archivos_funciones()
            if not any(
                excl in _ruta_relativa(a)
                for excl in SIN_EXCEPTION_OBLIGATORIA
            )
            and _ruta_relativa(a) not in ARCHIVOS_EXCLUIDOS_DEL_INSTALADOR
        ]
        if not cls.archivos:
            raise unittest.SkipTest(
                "No hay archivos de funciones de negocio para "
                "auditar (¿se movió database/functions/?)"
            )

    def test_funciones_de_negocio_tienen_bloque_exception(self) -> None:
        """El número de CREATE (OR REPLACE) FUNCTION en el archivo
        debe coincidir con el número de bloques EXCEPTION — si hay
        menos EXCEPTION que funciones, alguna quedó sin el patrón
        estándar de manejo de errores del proyecto."""
        infractores = []
        for archivo in self.archivos:
            contenido = archivo.read_text(encoding="utf-8")
            n_funciones = len(PATRON_CREATE_FUNCTION.findall(contenido))
            n_exception = len(
                re.findall(r"\bEXCEPTION\b", contenido)
            )
            if n_funciones > 0 and n_exception < n_funciones:
                infractores.append(
                    f"{_ruta_relativa(archivo)} "
                    f"({n_funciones} función(es), "
                    f"{n_exception} bloque(s) EXCEPTION)"
                )

        self.assertEqual(
            infractores,
            [],
            "Funciones de negocio sin bloque EXCEPTION completo: "
            f"{infractores}",
        )

    def test_bloque_exception_captura_4_variables_diagnostico(self) -> None:
        """Si un archivo tiene bloque EXCEPTION, debe declarar las 4
        variables de diagnóstico (w_exc_state/msg/detail/hint) — sin
        ellas, GET STACKED DIAGNOSTICS no tiene dónde guardar los
        datos que luego recibe smartcset_handle_sql_error()."""
        infractores = []
        for archivo in self.archivos:
            contenido = archivo.read_text(encoding="utf-8")
            if "EXCEPTION" not in contenido:
                continue
            faltantes = [
                var for var in VARIABLES_DIAGNOSTICO if var not in contenido
            ]
            if faltantes:
                infractores.append(
                    f"{_ruta_relativa(archivo)} (faltan: {faltantes})"
                )

        self.assertEqual(
            infractores,
            [],
            "Archivos con EXCEPTION pero variables de diagnóstico "
            f"incompletas: {infractores}",
        )


class TestAridadFuncionesSinDuplicados(unittest.TestCase):
    """Bug 20 (CLAUDE.md): un cambio de aridad sin DROP FUNCTION
    previo deja dos firmas de la misma función conviviendo en la
    BD real — este test las detecta automáticamente."""

    def test_bd_no_tiene_funciones_fun_con_firma_duplicada(self) -> None:
        """Ninguna función con prefijo fun_ (convención propia del
        proyecto, ver CLAUDE.md) debe tener más de una firma
        desplegada simultáneamente. Se excluyen a propósito las
        funciones de extensiones (pgvector/pgcrypto), que sí pueden
        tener overloads legítimos por diseño ajeno al proyecto."""
        try:
            salida = run_psql(
                "SELECT proname FROM pg_proc "
                "WHERE proname LIKE 'fun\\_%' "
                "GROUP BY proname HAVING COUNT(*) > 1 "
                "ORDER BY proname;"
            )
        except RuntimeError as exc:
            raise unittest.SkipTest(str(exc))

        duplicadas = [
            linea for linea in salida.splitlines() if linea.strip()
        ]
        self.assertEqual(
            duplicadas,
            [],
            "Funciones fun_* con firma duplicada en BD (cambio de "
            "aridad sin DROP FUNCTION IF EXISTS previo, Bug 20): "
            f"{duplicadas}",
        )


class TestInstaladorCubreTodasLasFunciones(unittest.TestCase):
    """Bug 2/4/17 + E7: todo archivo de función debe estar en FUNCS
    o explícitamente documentado como excluido — nunca "olvidado"."""

    @classmethod
    def setUpClass(cls) -> None:
        if not SETUP_SCRIPT.is_file():
            raise unittest.SkipTest(f"No se encuentra {SETUP_SCRIPT}")
        cls.contenido_setup = SETUP_SCRIPT.read_text(encoding="utf-8")
        cls.archivos = _archivos_funciones()

    def test_todo_archivo_en_disco_esta_en_funcs_o_excluido(self) -> None:
        """Cada .sql debe aparecer literalmente en setup_smartcset.sh
        o estar en ARCHIVOS_EXCLUIDOS_DEL_INSTALADOR (con razón
        documentada en CLAUDE.md) — si no está en ninguno de los dos,
        es una función que nadie sabe que existe para el instalador,
        exactamente el Bug 2 original."""
        no_cubiertos = []
        for archivo in self.archivos:
            rel = _ruta_relativa(archivo)
            en_funcs = rel in self.contenido_setup
            excluido = rel in ARCHIVOS_EXCLUIDOS_DEL_INSTALADOR
            if not en_funcs and not excluido:
                no_cubiertos.append(rel)

        self.assertEqual(
            no_cubiertos,
            [],
            "Archivos de función sin registrar en FUNCS y sin "
            "exclusión documentada (agregar a setup_smartcset.sh o "
            f"a ARCHIVOS_EXCLUIDOS_DEL_INSTALADOR): {no_cubiertos}",
        )

    def test_exclusiones_documentadas_siguen_existiendo(self) -> None:
        """Si un archivo de ARCHIVOS_EXCLUIDOS_DEL_INSTALADOR ya no
        existe en disco (se borró o se renombró), la lista de
        exclusiones queda desactualizada — señal de que hay que
        limpiarla, no un problema de seguridad pero sí de
        Congruencia (Pilar 2)."""
        rutas_en_disco = {_ruta_relativa(a) for a in self.archivos}
        obsoletas = sorted(
            ARCHIVOS_EXCLUIDOS_DEL_INSTALADOR - rutas_en_disco
        )
        self.assertEqual(
            obsoletas,
            [],
            "Exclusiones documentadas que ya no existen en disco "
            f"(limpiar ARCHIVOS_EXCLUIDOS_DEL_INSTALADOR): {obsoletas}",
        )

    def test_funciones_registradas_estan_desplegadas_en_bd(self) -> None:
        """Toda función definida en un archivo que SÍ está en FUNCS
        debe existir realmente en pg_proc — cubre el caso central del
        Bug 20: el .sql tenía la firma nueva, pero nunca se ejecutó
        contra la BD real, y sin este test nadie lo nota hasta que
        falla un endpoint en producción."""
        nombres_esperados: set[str] = set()
        for archivo in self.archivos:
            rel = _ruta_relativa(archivo)
            if rel in ARCHIVOS_EXCLUIDOS_DEL_INSTALADOR:
                continue
            if rel not in self.contenido_setup:
                continue
            contenido = archivo.read_text(encoding="utf-8")
            nombres_esperados.update(
                m.lower() for m in PATRON_CREATE_FUNCTION.findall(contenido)
            )

        if not nombres_esperados:
            raise unittest.SkipTest(
                "No se extrajeron nombres de función de los archivos "
                "registrados en FUNCS"
            )

        try:
            salida = run_psql("SELECT proname FROM pg_proc;")
        except RuntimeError as exc:
            raise unittest.SkipTest(str(exc))

        nombres_en_bd = {
            linea.strip().lower() for linea in salida.splitlines()
        }
        faltantes = sorted(nombres_esperados - nombres_en_bd)

        self.assertEqual(
            faltantes,
            [],
            "Funciones definidas en archivos de FUNCS pero no "
            f"desplegadas en la BD real: {faltantes}",
        )


class TestInyeccionSQLDinamica(unittest.TestCase):
    """E1-A03 (OWASP Injection) + MSPI Eje 8 (desarrollo seguro):
    ningún EXECUTE de SQL dinámico debe concatenar strings sin pasar
    por USING (parámetros vinculados)."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.archivos = _archivos_funciones()
        if not cls.archivos:
            raise unittest.SkipTest(
                f"No se encontraron archivos .sql en {FUNCTIONS_DIR}"
            )

    def test_ningun_archivo_ejecuta_sql_dinamico_sin_using(self) -> None:
        """Hoy (2026-07) no hay SQL dinámico real en el proyecto —
        los únicos EXECUTE activos son cláusulas `EXECUTE FUNCTION`
        de CREATE TRIGGER (no ejecutan SQL dinámico, están excluidas
        del patrón buscado). Este test es un guardián de regresión:
        si alguien agrega EXECUTE con concatenación en el futuro
        (p. ej. para el módulo de carga SENA), debe fallar aquí antes
        de llegar a producción."""
        infractores = []
        for archivo in self.archivos:
            contenido = _sin_comentarios(
                archivo.read_text(encoding="utf-8")
            )
            for match in PATRON_EXECUTE_RIESGOSO.finditer(contenido):
                fragmento = match.group(0)
                if "USING" in fragmento.upper():
                    continue  # parametrizado, seguro
                infractores.append(
                    f"{_ruta_relativa(archivo)}: {fragmento.strip()[:80]}"
                )

        self.assertEqual(
            infractores,
            [],
            "SQL dinámico con concatenación sin USING (riesgo de "
            f"inyección SQL, E1-A03): {infractores}",
        )


if __name__ == "__main__":
    unittest.main()
