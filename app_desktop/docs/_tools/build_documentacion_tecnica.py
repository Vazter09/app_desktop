# -*- coding: utf-8 -*-
"""Genera app_desktop/DOCUMENTACION_TECNICA.md (monolítico as-built)."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
OUT = ROOT / "DOCUMENTACION_TECNICA.md"


def read(rel: str) -> str:
    return (DOCS / rel).read_text(encoding="utf-8")


def strip_meta(text: str) -> str:
    """Quita título H1 y bloque metadata hasta el primer --- de cierre."""
    lines = text.splitlines()
    i = 0
    if lines and lines[0].startswith("# "):
        i = 1
    while i < len(lines) and lines[i].strip() == "":
        i += 1
    # saltar filas **Módulo:** / **Responsable:** etc. hasta ---
    while i < len(lines):
        s = lines[i].strip()
        if s == "---":
            i += 1
            break
        if s.startswith("**") or s.startswith(">"):
            i += 1
            continue
        if s == "":
            i += 1
            continue
        break
    while i < len(lines) and lines[i].strip() == "":
        i += 1
    body = "\n".join(lines[i:]).rstrip() + "\n"
    return body


def demote_headings(body: str, levels: int = 1) -> str:
    """Baja niveles de heading # → ## etc. (máx 6)."""

    def repl(m: re.Match[str]) -> str:
        hashes = m.group(1)
        n = min(6, len(hashes) + levels)
        return "#" * n + m.group(2)

    return re.sub(r"^(#{1,5})(\s+.+)$", repl, body, flags=re.M)


# Remapeo de rutas documentales antiguas → anclas / secciones del monolítico
_REF_MAP: list[tuple[str, str]] = [
    ("Detalle en `10-requisitos-de-calidad.md`.", "Detalle en la sección 10 (requisitos de calidad) de este documento."),
    (
        "Visión, SRS, arquitectura y diseño detallado en `docs/01`–`04`; seguridad y trazabilidad en `docs/09` y `docs/11`.",
        "Visión y SRS: PARTE B de este documento; arquitectura: PARTE A; seguridad y trazabilidad: §8, §11 y PARTE I.",
    ),
    ("Inventario de endpoints: `../07-contrato-integracion.md`.", "Inventario de endpoints: PARTE D (contrato HTTP) de este documento."),
    ("Índice completo: `09-decisiones-indice-adr.md`.", "Índice completo: sección 9; textos ADR: PARTE C."),
    ("Detalle operativo: `../05-manual-instalacion.md`.", "Detalle operativo: PARTE F §F.1 (instalación) de este documento."),
    ("Detalle: `../09-seguridad-mspi.md`.", "Detalle: §8 (conceptos transversales) y PARTE F §F.3 (incidentes)."),
    ("Trazabilidad RF↔tests↔MSPI: `../11-matriz-trazabilidad.md`.", "Trazabilidad RF↔tests↔MSPI: PARTE I §I.1."),
    (
        "Fuentes: `../09-seguridad-mspi.md`, `../11-matriz-trazabilidad.md`, `../08-plan-y-evidencia-pruebas.md`.",
        "Fuentes: §8, §11, PARTE I §I.1 y suite `tests/` (35 casos).",
    ),
    (
        "Definiciones de dominio SmartCSET más amplias: `../01-vision-y-alcance.md` §9. Este glosario prioriza términos necesarios para leer las secciones arc42 de `app_desktop`.",
        "Este glosario prioriza términos necesarios para leer las secciones arc42 de `app_desktop`.",
    ),
    (
        "(documentado como no implementado en `../09-seguridad-mspi.md`).",
        "(documentado como no implementado en §8 / ADR-03).",
    ),
    (
        "- Ejemplos: `ejemplos-request-response.md`\n- OpenAPI manual: [`openapi-desktop.yaml`](openapi-desktop.yaml)\n- Seguridad: `../09-seguridad-mspi.md`",
        "- Ejemplos: §D.2 de este documento\n- OpenAPI manual: `app_desktop/docs/api/openapi-desktop.yaml`\n- Seguridad: §8 y PARTE F §F.3",
    ),
    (
        "Ver también: `contrato-http.md`, [`openapi-desktop.yaml`](openapi-desktop.yaml).",
        "Ver también: §D.1 y `app_desktop/docs/api/openapi-desktop.yaml`.",
    ),
    ("Ver: `diccionario-de-datos.md`, `catalogo-funciones.md`.", "Ver: §E.2 y §E.3 de este documento."),
    (
        "- ER: `diagrama-er.md`\n- Diccionario: `diccionario-de-datos.md`\n- Contrato HTTP: `../api/contrato-http.md`",
        "- ER: §E.1\n- Diccionario: §E.3\n- Contrato HTTP: PARTE D",
    ),
    ("Clasificación según `../09-seguridad-mspi.md` y Ley 1581", "Clasificación según §8 / PARTE I y Ley 1581"),
    (
        "- ER: `diagrama-er.md`\n- Funciones: `catalogo-funciones.md`\n- Seguridad: `../09-seguridad-mspi.md`\n- ADR dimensión: `../adr/ADR-04-sface-128-dims.md`",
        "- ER: §E.1\n- Funciones: §E.2\n- Seguridad: §8\n- ADR dimensión: PARTE C ADR-04",
    ),
    ("| Seguridad | Sesión + HTTPS + validación E6 | docs/09, tests biometría |", "| Seguridad | Sesión + HTTPS + validación E6 | §8, tests biometría |"),
    ("Despliegue TLS producción: `../operacion/despliegue-produccion.md`.", "Despliegue TLS producción: PARTE F §F.4."),
    ("Runbook incidentes (Eje 8): `../operacion/incidentes-seguridad.md`.", "Runbook incidentes (Eje 8): PARTE F §F.3."),
    (
        "Guías de usuario alineadas: facial RF-03/05/06 → `../usuario/guias/registrar-ingreso-facial.md`; manual RF-07 → `registrar-ingreso-manual.md`; enrolar RF-04 → `enrolar-rostro.md`; pistola RF-08 → `lectura-pistola.md`.",
        "Guías de usuario alineadas: facial RF-03/05/06 → §G.2; manual RF-07 → §G.3; enrolar RF-04 → §G.4; pistola RF-08 → §G.5.",
    ),
    (
        "- Requisitos fuente: `../02-especificacion-requisitos.md`\n- Plan de pruebas: `../08-plan-y-evidencia-pruebas.md`\n- Seguridad: `../09-seguridad-mspi.md`\n- Checklist docs: `../CHECKLIST_DOCUMENTACION.md`\n- Explicación diseño: `../usuario/explicacion.md`",
        "- Requisitos: PARTE B\n- Plan de pruebas: suite `tests/` + §10\n- Seguridad: §8 y PARTE F §F.3\n- Explicación diseño: §G.7",
    ),
]


def scrub_links(body: str) -> str:
    """Convierte enlaces md relativos a menciones de sección / ruta código."""
    # [texto](ruta.md) → texto
    body = re.sub(r"\[([^\]]+)\]\((?!https?://)[^)]+\.md(?:#[^)]*)?\)", r"\1", body)
    # [texto](../src/...) → `ruta`
    body = re.sub(
        r"\[([^\]]+)\]\((?:\.\./)+src/([^)]+)\)",
        r"`src/\2`",
        body,
    )
    body = re.sub(
        r"\[([^\]]+)\]\((?:\.\./)+(backend|database|frontend)/([^)]+)\)",
        r"`\1/\2`",
        body,
    )
    for old, new in _REF_MAP:
        body = body.replace(old, new)

    # ADR table links → PARTE C
    body = re.sub(
        r"\| `(?:\.\./)?adr/(ADR-\d+[-\w]*)\.md` \|",
        r"| PARTE C `\1` |",
        body,
    )
    body = body.replace("`../adr/ADR-01-tkinter-stdlib.md`", "PARTE C ADR-01")
    body = body.replace("`../adr/ADR-02-sesion-web-real.md`", "PARTE C ADR-02")
    body = body.replace("`../adr/ADR-03-motor-biometrico-in-process.md`", "PARTE C ADR-03")
    body = body.replace("`../adr/ADR-04-sface-128-dims.md`", "PARTE C ADR-04")
    body = body.replace("`../adr/ADR-05-url-preconfigurada.md`", "PARTE C ADR-05")
    body = body.replace("`../adr/ADR-06-pyinstaller-onefile.md`", "PARTE C ADR-06")

    # Operación / usuario cross-refs frecuentes
    replacements = {
        "`despliegue-produccion.md`": "§F.4",
        "`backup-restauracion.md`": "§F.2",
        "`instalacion.md`": "§F.1",
        "`incidentes-seguridad.md`": "§F.3",
        "`../usuario/tutorial-primer-uso.md`": "§G.1",
        "`tutorial-primer-uso.md`": "§G.1",
        "`guias/registrar-ingreso-facial.md`": "§G.2",
        "`registrar-ingreso-facial.md`": "§G.2",
        "`guias/registrar-ingreso-manual.md`": "§G.3",
        "`registrar-ingreso-manual.md`": "§G.3",
        "`guias/enrolar-rostro.md`": "§G.4",
        "`enrolar-rostro.md`": "§G.4",
        "`guias/lectura-pistola.md`": "§G.5",
        "`lectura-pistola.md`": "§G.5",
        "`referencia-roles.md`": "§G.6",
        "`explicacion.md`": "§G.7",
        "`../explicacion.md`": "§G.7",
        "`matriz-trazabilidad.md`": "§I.1",
        "`../anexos/matriz-trazabilidad.md`": "§I.1",
        "`contrato-http.md`": "§D.1",
        "`ejemplos-request-response.md`": "§D.2",
        "`diagrama-er.md`": "§E.1",
        "`catalogo-funciones.md`": "§E.2",
        "`diccionario-de-datos.md`": "§E.3",
        "`04-estrategia-de-solucion.md`": "sección 4",
        "`../09-seguridad-mspi.md`": "§8 / §F.3",
        "`../07-contrato-integracion.md`": "PARTE D",
        "`../05-manual-instalacion.md`": "§F.1",
        "`../11-matriz-trazabilidad.md`": "§I.1",
        "`../08-plan-y-evidencia-pruebas.md`": "§10 / `tests/`",
        "`../01-vision-y-alcance.md`": "PARTE B",
        "`../02-especificacion-requisitos.md`": "PARTE B",
        "`../03-arquitectura.md`": "PARTE A",
        "`../04-diseno-detallado.md`": "PARTE A / PARTE C",
        "`../10-operacion-y-mantenimiento.md`": "PARTE F",
        "`../CHECKLIST_DOCUMENTACION.md`": "`docs/CHECKLIST_DOCUMENTACION.md`",
        "`../../packaging/README.md`": "`app_desktop/packaging/README.md`",
        "`../../CHANGELOG.md`": "`app_desktop/CHANGELOG.md`",
        "`../../README.md`": "`app_desktop/README.md`",
        "`../../HANDOFF.md`": "`app_desktop/HANDOFF.md`",
        "`../../REGLAS_APP_ESCRITORIO_SGI.md`": "`app_desktop/REGLAS_APP_ESCRITORIO_SGI.md`",
        "`../../../CLAUDE.md`": "`CLAUDE.md` (raíz del proyecto)",
        "`../operacion/instalacion.md`": "§F.1",
        "`../operacion/despliegue-produccion.md`": "§F.4",
        "`../operacion/incidentes-seguridad.md`": "§F.3",
        "`../operacion/backup-restauracion.md`": "§F.2",
        "`../historial/CHANGELOG.md`": "PARTE H",
        "`../README.md`": "`docs/README.md`",
        "`operacion/instalacion.md`": "§F.1",
        "`que-debe-contener-un-proyecto.md`": "§I.2",
        "`CHECKLIST_DOCUMENTACION.md`": "`docs/CHECKLIST_DOCUMENTACION.md`",
    }
    for old, new in replacements.items():
        body = body.replace(old, new)

    body = body.replace("34 tests", "35 tests")
    body = body.replace("**34**", "**35**")
    body = body.replace("Suite 34", "Suite 35")
    body = body.replace("Integración 34", "Integración 35")
    body = body.replace(
        "### `test_smartcset_client.py` (17)",
        "### `test_smartcset_client.py` (18)",
    )
    body = body.replace(
        "| `test_smartcset_client.py` | 17 |",
        "| `test_smartcset_client.py` | 18 |",
    )
    body = body.replace("| **Total** | **34** |", "| **Total** | **35** |")
    body = body.replace("34 casos", "35 casos")
    body = body.replace("Inventario de pruebas (34 casos)", "Inventario de pruebas (35 casos)")
    body = body.replace("E10 — SDLC seguro | Suite unittest, sin mocks | 34 tests totales",
                        "E10 — SDLC seguro | Suite unittest, sin mocks | 35 tests totales")
    return body


def section_from(rel: str, demote: int = 1) -> str:
    return scrub_links(demote_headings(strip_meta(read(rel)), demote))


def build() -> str:
    parts: list[str] = []

    parts.append(
        """# Documentación Técnica — App de Escritorio SGI (SmartCSET)

| Campo | Valor |
|-------|-------|
| **Módulo** | `app_desktop` |
| **Tipo** | Documentación técnica monolítica as-built |
| **Responsable** | Equipo de Desarrollo |
| **Última revisión** | 2026-09-14 |
| **Estado** | Publicado |
| **Ejes MSPI** | 3, 5, 6, 7, 8 |
| **Estándares aplicados** | arc42 · C4 Model · ADR · ISO/IEC/IEEE 29148 · ISO/IEC 25010:2023 · ISO/IEC 27001:2022 Anexo A · Diátaxis · 7 reglas de redacción SmartCSET |
| **Fuente de código** | `app_desktop/src/` (as-built; no el árbol histórico `app/`) |
| **Alcance** | Cliente de portería Windows + endpoints/tablas/funciones que consume en el backend SmartCSET |

Este documento es **autocontenido**. Consolida arquitectura, requisitos, decisiones, API, base de datos (alcance desktop), operación, guías de usuario, historial y anexos MSPI. Las afirmaciones técnicas se verifican contra el código en `app_desktop/src/` y `app_desktop/tests/` a la fecha de revisión.

**Hechos as-built de cierre (2026-09-14):**

- Código en `src/`; entrada `src/main.py`; tests en `tests/` (**35** casos unittest).
- Post-login: `AppShell` navega solo a `ingreso` (sin sidebar). Páginas `inicio` / `salida` / `entradas` existen en código pero no están expuestas al operario.
- Motor facial **in-process**: YuNet + SFace, embedding **128** dimensiones.
- Huella: UI + endpoints + templates sintéticos; **sin lector hardware** (`capturar_desde_lector` → `NotImplementedError`).
- Cliente HTTP stdlib (`urllib`), sesión PHP (`PHPSESSID`), timeout 15 s, `verify_tls` configurable.
- Empaque: `SmartCSET_Porteria.exe` (PyInstaller onefile).

---

## Tabla de contenidos

1. [PARTE A — Arquitectura (arc42)](#parte-a--arquitectura-arc42)
2. [PARTE B — Requisitos (ISO/IEC/IEEE 29148)](#parte-b--requisitos-isoiecieee-29148)
3. [PARTE C — Decisiones ADR](#parte-c--decisiones-adr)
4. [PARTE D — API / contrato HTTP](#parte-d--api--contrato-http)
5. [PARTE E — Base de datos (alcance desktop)](#parte-e--base-de-datos-alcance-desktop)
6. [PARTE F — Operación](#parte-f--operación)
7. [PARTE G — Usuario (Diátaxis)](#parte-g--usuario-diátaxis)
8. [PARTE H — Historial](#parte-h--historial)
9. [PARTE I — Anexos](#parte-i--anexos)

---

# PARTE A — Arquitectura (arc42)

"""
    )

    # --- §1 ---
    parts.append("## 1. Introducción y objetivos\n\n")
    parts.append(section_from("arquitectura/01-introduccion-y-objetivos.md"))
    parts.append(
        "\n> **Corrección as-built (2026-09-14):** la suite unittest suma **35** casos "
        "(`test_smartcset_client.py` 18 + `test_scan_capture.py` 17), no 34.\n\n"
    )

    # --- §2 ---
    parts.append("## 2. Restricciones\n\n")
    parts.append(section_from("arquitectura/02-restricciones.md"))
    parts.append(
        "\n> **Nota as-built huella (2026-09-14):** el área de huella no es solo decoración: "
        "existen endpoints `biometria/huella_*`, UI de captura simulada y 3 tests. "
        "Sigue **sin SDK de lector físico**; el template es sintético.\n\n"
    )

    # --- §3 ---
    parts.append("## 3. Contexto y alcance\n\n")
    parts.append(section_from("arquitectura/03-contexto-y-alcance.md"))
    parts.append(
        """
### 3.8 Diagrama C4 — contexto (nivel 1)

```mermaid
C4Context
    title App Desktop SGI — contexto
    Person(operario, "Operario portería", "Login, facial, manual, pistola")
    Person(ti, "TI / instalador", "Instala .exe y edita app_config.json")
    System(desktop, "App Desktop SmartCSET", "Cliente Tkinter + FaceEmbedder in-process")
    System_Ext(backend, "Backend SmartCSET", "Apache HTTPS + PHP + PostgreSQL/pgvector")
    System_Ext(cam, "Webcam USB", "Frames OpenCV")
    System_Ext(pistola, "Pistola códigos", "HID teclado")
    Rel(operario, desktop, "Opera")
    Rel(ti, desktop, "Configura base_url / TLS")
    Rel(desktop, backend, "HTTPS JSON + PHPSESSID")
    Rel(desktop, cam, "Captura")
    Rel(operario, pistola, "Escanea documento")
    Rel(pistola, desktop, "Texto HID")
```

"""
    )

    # --- §4 ---
    parts.append("## 4. Estrategia de solución\n\n")
    parts.append(section_from("arquitectura/04-estrategia-de-solucion.md"))
    parts.append(
        "\n> Los ADR completos están en la [PARTE C](#parte-c--decisiones-adr) de este documento. "
        "Meta de tests: **35** casos (no 34).\n\n"
    )

    # --- §5 ---
    parts.append("## 5. Vista de bloques\n\n")
    parts.append(section_from("arquitectura/05-vista-de-bloques.md"))
    parts.append(
        """
### 5.8 Diagrama C4 — contenedores (nivel 2)

```mermaid
flowchart TB
  subgraph desktopApp [Contenedor_AppDesktop]
    ui[UI_Tkinter]
    motor[FaceEmbedder_ONNX]
    client[SmartcsetClient_urllib]
    ui --> motor
    ui --> client
  end
  subgraph server [Contenedor_Backend]
    php[Routers_PHP]
    pl[Funciones_PLpgSQL]
    pg[(PostgreSQL)]
    fs[Filesystem_fotos]
    php --> pl
    pl --> pg
    php --> fs
  end
  client -->|"HTTPS + cookie"| php
```

"""
    )

    # --- §6-8 ---
    parts.append("## 6. Vista de runtime\n\n")
    parts.append(section_from("arquitectura/06-vista-de-runtime.md"))
    parts.append("\n## 7. Vista de despliegue\n\n")
    parts.append(section_from("arquitectura/07-vista-de-despliegue.md"))
    parts.append("\n## 8. Conceptos transversales\n\n")
    parts.append(section_from("arquitectura/08-conceptos-transversales.md"))
    parts.append(
        "\n> Suite de pruebas: **35** casos. Sin CI ni tests UI Tkinter (deuda conocida).\n\n"
    )

    # --- §9 index (short; full ADRs in Part C) ---
    parts.append("## 9. Decisiones de arquitectura (índice)\n\n")
    parts.append(section_from("arquitectura/09-decisiones-indice-adr.md"))
    parts.append(
        "\nLos textos completos de cada ADR están en la [PARTE C](#parte-c--decisiones-adr).\n\n"
    )

    # --- §10 quality + ISO 25010 ---
    parts.append("## 10. Requisitos de calidad\n\n")
    parts.append(section_from("arquitectura/10-requisitos-de-calidad.md"))
    parts.append(
        """
### 10.8 Addendum ISO/IEC 25010:2023 — trazabilidad

Los **5 Pilares** SmartCSET (Coherencia, Congruencia, Funcionalidad, Estabilidad, Seguridad Total)
siguen siendo el criterio de aceptación interno. ISO/IEC 25010:2023 se aplica como capa de
trazabilidad adicional, sin reemplazar esos pilares.

| Característica ISO 25010 | Pilar / evidencia en app_desktop | Estado |
|--------------------------|----------------------------------|--------|
| Adecuación funcional | Funcionalidad — RF-01…RF-11 operativos; matriz PARTE I | Cubierto |
| Eficiencia de desempeño | Estabilidad — cámara usable; sin bench formal de latencia facial | Parcial |
| Compatibilidad | Congruencia — mismo backend web; sin matriz de SO/navegador (es desktop nativo) | Cubierto (desktop) |
| Usabilidad | Una pantalla post-login; sin auditoría WCAG formal | Brecha explícita |
| Fiabilidad | Hooks excepción + logout + fallback manual | Cubierto |
| Seguridad | Sesión PHP, HTTPS, E6 fotos; E2 diferido | Parcial (E2) |
| Mantenibilidad | `src/`, PEP8/`ruff`, deps fijadas, 35 tests | Cubierto |
| Flexibilidad | PostgreSQL único en servidor (ADR institucional); cliente acoplado a API SmartCSET | Decisión deliberada |
| Protección / seguridad física | Control físico del PC portería (fuera del software) | Fuera de alcance código |

**Hallazgos no forzados a “cubierto”:** usabilidad accesible (WCAG) sin investigar; cifrado E2
ausente; medición formal de rendimiento facial ausente.

"""
    )

    # --- §11 risks + ISO 27001 ---
    parts.append("## 11. Riesgos y deuda técnica\n\n")
    parts.append(section_from("arquitectura/11-riesgos-y-deuda-tecnica.md"))
    parts.append(
        """
### 11.7 Clasificación ISO/IEC 27001:2022 Anexo A

Clasificación de trazabilidad normativa sobre el registro de riesgos §11.1.
No constituye una auditoría SGSI nueva; no altera severidad/probabilidad ya asignadas.

| ID | Tema Anexo A | Justificación breve |
|----|--------------|---------------------|
| R1 | Tecnológico | Controles biométricos / umbral / UI de confirmación |
| R2 | Tecnológico | Configuración TLS del cliente |
| R3 | Físico | Acceso al puesto de portería |
| R4 | Tecnológico | Almacenamiento de fotos en filesystem servidor |
| R5 | Organizacional / Personas | Proceso de enrolamiento y consentimiento |
| R6 | Tecnológico | Dependencia de red/backend |
| R7 | Tecnológico | Gestión de sesión / cierre |
| R8 | Tecnológico | Pipeline de build |
| R9 | Tecnológico | Deuda de navegación / código muerto expuesto |
| R10 | Tecnológico | Feature placeholder confundible |

**Lectura agregada:** 8 tecnológicos, 1 físico, 1 organizacional/personas.
Deudas de §11.2 sin ID de riesgo (CI, semver, LICENSE) se tratan como mantenimiento/proceso
sin tema Anexo A directo.

"""
    )

    # --- §12 ---
    parts.append("## 12. Glosario\n\n")
    parts.append(section_from("arquitectura/12-glosario.md"))

    # ========== PARTE B ISO 29148 ==========
    parts.append(
        """
---

# PARTE B — Requisitos (ISO/IEC/IEEE 29148)

Cadena StRS → SyRS → SRS. Ningún requisito se inventa: se extraen del as-built verificado
(arquitectura §1–§11, matriz de trazabilidad, código en `src/`).

## B.1 StRS — Especificación de interesados

| ID | Interesado | Necesidad |
|----|------------|-----------|
| STR-01 | Operario portería | Registrar ingresos/salidas con identificación rápida y fiable en horas pico |
| STR-02 | Operario portería | Continuar operando si falla la cámara o el match facial |
| STR-03 | Administrador sistema | Misma autenticación y auditoría que la web (`usr_insert` real) |
| STR-04 | TI / instalador | Desplegar un entregable Windows sin instalar Python a mano |
| STR-05 | TI / instalador | Configurar URL/TLS una vez, sin que el operario edite red |
| STR-06 | Cumplimiento MSPI / SENA | Proteger datos biométricos y personales en tránsito y operación |
| STR-07 | Backend / Equipo de Desarrollo | No duplicar reglas de negocio en el cliente |
| STR-08 | Centro de formación | Un puesto dedicado (pantalla completa) frente al navegador genérico |
| STR-09 | Auditoría / SIEM | Trazar método de autenticación (manual/QR/barras/facial) por evento |

## B.2 SyRS — Especificación de sistema

### Requisitos funcionales de sistema

| ID | Requisito | Trazabilidad StRS |
|----|-----------|-------------------|
| SYS-F-01 | El sistema autentica al operario contra SmartCSET con sesión web | STR-03, STR-06 |
| SYS-F-02 | El sistema ofrece identificación facial local + registro remoto | STR-01, STR-08 |
| SYS-F-03 | El sistema permite enrolar rostro con foto de referencia | STR-01, STR-06 |
| SYS-F-04 | El sistema confirma visualmente el match antes de registrar | STR-01, STR-09 |
| SYS-F-05 | El sistema registra ingreso o salida según estado en servidor | STR-01, STR-07 |
| SYS-F-06 | El sistema acepta captura manual y pistola de códigos | STR-01, STR-02 |
| SYS-F-07 | El sistema degrada a manual si falla biometría | STR-02, STR-05 |
| SYS-F-08 | El sistema se empaqueta como ejecutable Windows configurado por TI | STR-04, STR-05 |

### Requisitos no funcionales de sistema

| ID | Requisito | Trazabilidad StRS |
|----|-----------|-------------------|
| SYS-NF-01 | Canal HTTPS hacia el backend; TLS verificable en producción | STR-06 |
| SYS-NF-02 | Timeout de red acotado; errores visibles al operario | STR-02 |
| SYS-NF-03 | Auditoría de usuario real en persistencia | STR-03, STR-09 |
| SYS-NF-04 | Sin base de datos local ni modo offline | STR-07 |
| SYS-NF-05 | Dependencias de terceros mínimas y fijadas | STR-04, STR-06 |
| SYS-NF-06 | Tests de integración reales (sin mocks de BD) | STR-07 |
| SYS-NF-07 | Logs locales sin volcar embeddings/fotos/documentos | STR-06 |
| SYS-NF-08 | UI en español alineada a identidad corporativa | STR-08 |
| SYS-NF-09 | Consentimiento biométrico UI y cifrado E2: diferidos / pendientes | STR-06 |

## B.3 SRS — Especificación de software

### Requisitos funcionales de software

| ID | Requisito | Implementación | SyRS |
|----|-----------|----------------|------|
| RF-01 | Login/logout sesión PHP | `login_view.py`, `smartcset_client.py`, `main.py` | SYS-F-01 |
| RF-02 | Pantalla portería unificada post-login | `shell.py`, `ingreso.py`, `facial_modal.py` | SYS-F-02 |
| RF-03 | Identificación facial 128-d | `motor/embeddings.py`, `facial_modal.py` | SYS-F-02 |
| RF-04 | Enrolamiento con foto JPG | `facial_modal.py`, `biometria_enrolar` | SYS-F-03 |
| RF-05 | Confirmación visual (foto servidor prioritaria) | `identification_confirmation_modal.py` | SYS-F-04 |
| RF-06 | Ingreso/salida vía API | `facial_modal.py`, `ingreso_form_panel.py` | SYS-F-05 |
| RF-07 | Captura manual | `ingreso_form_panel.py`, `field_validators.py` | SYS-F-06 |
| RF-08 | Pistola QR/barras/PDF417 | `scan_capture.py` | SYS-F-06 |
| RF-09 | Fallback si falla facial | formulario permanece usable | SYS-F-07 |
| RF-10 | Cierre de sesión al salir | `main.py` close/atexit → `logout` | SYS-F-01 |
| RF-11 | Empaquetado `.exe` | `packaging/SmartCSET_Porteria.spec` | SYS-F-08 |
| RF-12 | Dashboard inicio | `pages/inicio.py` — **no expuesto UI** | — |
| RF-13 | Página salida dedicada | `pages/salida.py` — **no expuesto UI** | — |
| RF-14 | CRUD entradas | `pages/entradas.py` — **no expuesto UI** | — |
| RF-15 | Huella hardware | placeholder sintético + endpoints prueba | — |

### Requisitos no funcionales de software

| ID | Requisito | Implementación | SyRS |
|----|-----------|----------------|------|
| RNF-01 | HTTPS + TLS configurable | `config.py`, `SmartcsetClient` | SYS-NF-01 |
| RNF-02 | Timeout HTTP 15 s | `_request` | SYS-NF-02 |
| RNF-03 | Cliente HTTP thread-safe | `threading.RLock` | SYS-NF-02 |
| RNF-04 | No seguir redirects 3xx | `_NoFollowRedirectHandler` | SYS-NF-01 |
| RNF-05 | Logs rotativos 2 MiB × 5 | `app_log.py` | SYS-NF-07 |
| RNF-06 | PEP8 / `ruff` | política `src/` | SYS-NF-05 |
| RNF-07 | Deps `==` en requirements | `requirements.txt` | SYS-NF-05 |
| RNF-08 | Tests sin mocks BD | `tests/` (35) | SYS-NF-06 |
| RNF-09 | Tema corporativo | `ui/theme.py` | SYS-NF-08 |
| RNF-10 | Responsive básico | `ui/responsive.py` | SYS-NF-08 |

"""
    )

    # ========== PARTE C ADRs ==========
    parts.append(
        """
---

# PARTE C — Decisiones ADR

"""
    )
    for adr in [
        "adr/ADR-01-tkinter-stdlib.md",
        "adr/ADR-02-sesion-web-real.md",
        "adr/ADR-03-motor-biometrico-in-process.md",
        "adr/ADR-04-sface-128-dims.md",
        "adr/ADR-05-url-preconfigurada.md",
        "adr/ADR-06-pyinstaller-onefile.md",
    ]:
        raw = read(adr)
        title = raw.splitlines()[0].lstrip("# ").strip()
        parts.append(f"## {title}\n\n")
        parts.append(section_from(adr, demote=1))
        parts.append("\n")

    # ========== PARTE D API ==========
    parts.append(
        """
---

# PARTE D — API / contrato HTTP

La app **no expone** API propia. Documenta el contrato del cliente `SmartcsetClient`
hacia el backend SmartCSET.

## D.1 Contrato HTTP

"""
    )
    parts.append(section_from("api/contrato-http.md", demote=1))
    parts.append("\n## D.2 Ejemplos request / response\n\n")
    parts.append(section_from("api/ejemplos-request-response.md", demote=1))
    parts.append(
        """
## D.3 OpenAPI (resumen)

Existe especificación manual en `app_desktop/docs/api/openapi-desktop.yaml`
(no generada automáticamente). Cubre los paths que usa el desktop:

| Path | Uso |
|------|-----|
| `/routers/auth/v1/login.php` | Login |
| `/routers/auth/v1/logout.php` | Logout |
| `/routers/porteria/v1/catalogos.php` | Catálogos |
| `/routers/porteria/v1/ingreso/*` | Consultar / registrar / actualizar captura / hoy |
| `/routers/porteria/v1/salida/*` | Consultar / registrar / hoy |
| `/routers/porteria/v1/biometria/enrolar.php` | Enrolar facial |
| `/routers/porteria/v1/biometria/identificar.php` | Identificar facial |
| `/routers/porteria/v1/biometria/huella_*` | Huella placeholder |
| `/routers/entradas/v1/guardar.php` / `eliminar.php` | CRUD entradas (admin; UI no expuesta) |

`health.php` **no** tiene wrapper en `SmartcsetClient`.

"""
    )

    # ========== PARTE E BD ==========
    parts.append(
        """
---

# PARTE E — Base de datos (alcance desktop)

## E.1 Diagrama ER

"""
    )
    parts.append(section_from("base_de_datos/diagrama-er.md", demote=1))
    parts.append("\n## E.2 Catálogo de funciones PL/pgSQL\n\n")
    parts.append(section_from("base_de_datos/catalogo-funciones.md", demote=1))
    parts.append("\n## E.3 Diccionario de datos\n\n")
    parts.append(section_from("base_de_datos/diccionario-de-datos.md", demote=1))

    # ========== PARTE F Ops ==========
    parts.append(
        """
---

# PARTE F — Operación

## F.1 Instalación desde cero

"""
    )
    parts.append(section_from("operacion/instalacion.md", demote=1))
    parts.append("\n## F.2 Backup y restauración\n\n")
    parts.append(section_from("operacion/backup-restauracion.md", demote=1))
    parts.append("\n## F.3 Incidentes de seguridad\n\n")
    parts.append(section_from("operacion/incidentes-seguridad.md", demote=1))
    parts.append("\n## F.4 Checklist despliegue producción\n\n")
    parts.append(section_from("operacion/despliegue-produccion.md", demote=1))

    # ========== PARTE G Usuario ==========
    parts.append(
        """
---

# PARTE G — Usuario (Diátaxis)

## G.1 Tutorial — primer uso

"""
    )
    parts.append(section_from("usuario/tutorial-primer-uso.md", demote=1))
    parts.append("\n## G.2 Guía — registrar ingreso facial\n\n")
    parts.append(section_from("usuario/guias/registrar-ingreso-facial.md", demote=1))
    parts.append("\n## G.3 Guía — registrar ingreso manual\n\n")
    parts.append(section_from("usuario/guias/registrar-ingreso-manual.md", demote=1))
    parts.append("\n## G.4 Guía — enrolar rostro\n\n")
    parts.append(section_from("usuario/guias/enrolar-rostro.md", demote=1))
    parts.append("\n## G.5 Guía — lectura con pistola\n\n")
    parts.append(section_from("usuario/guias/lectura-pistola.md", demote=1))
    parts.append("\n## G.6 Referencia — roles y permisos\n\n")
    parts.append(section_from("usuario/referencia-roles.md", demote=1))
    parts.append("\n## G.7 Explicación — porqués del diseño\n\n")
    parts.append(section_from("usuario/explicacion.md", demote=1))

    # ========== PARTE H Historial ==========
    parts.append(
        """
---

# PARTE H — Historial

## H.1 Changelog

"""
    )
    parts.append(section_from("historial/CHANGELOG.md", demote=1))
    parts.append(
        """
### Entrada de documentación (2026-09-14)

- Publicación de `DOCUMENTACION_TECNICA.md` monolítico (arc42 + C4 + ADR + ISO 29148/25010/27001 + Diátaxis).
- Corrección de conteo de tests a **35** y aclaración as-built de huella (endpoints + sintético, sin hardware).

"""
    )

    # ========== PARTE I Anexos ==========
    parts.append(
        """
---

# PARTE I — Anexos

## I.1 Matriz de trazabilidad MSPI

"""
    )
    parts.append(section_from("anexos/matriz-trazabilidad.md", demote=1))
    parts.append("\n## I.2 Qué debe contener un proyecto de software (referencia)\n\n")
    parts.append(section_from("anexos/que-debe-contener-un-proyecto.md", demote=1))

    parts.append(
        """
---

## Cierre documental

| Verificación | Resultado |
|--------------|-----------|
| arc42 §1–§12 | Incluidos en PARTE A |
| C4 contexto + contenedores | Mermaid en §3.8 y §5.8 |
| ADR-01…06 textos completos | PARTE C |
| ISO 29148 StRS/SyRS/SRS | PARTE B |
| ISO 25010 addendum | §10.8 |
| ISO 27001 Anexo A | §11.7 |
| Diátaxis | PARTE G |
| API + BD + operación + historial + matriz | PARTES D–I |
| Contraste código `src/` | Hechos de cabecera 2026-09-14 |

**Responsable:** Equipo de Desarrollo · **Revisión:** 2026-09-14
"""
    )

    return "\n".join(parts)


def main() -> None:
    text = build()
    # Normalizar finales de línea excesivos
    text = re.sub(r"\n{4,}", "\n\n\n", text)
    OUT.write_text(text, encoding="utf-8", newline="\n")
    lines = text.count("\n") + 1
    print(f"Wrote {OUT} ({lines} lines, {len(text)} chars)")


if __name__ == "__main__":
    main()
