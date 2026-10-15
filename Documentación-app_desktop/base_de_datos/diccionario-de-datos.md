# Diccionario de datos — alcance desktop / MSPI

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 6, 8  

Clasificación según [`../09-seguridad-mspi.md`](../09-seguridad-mspi.md) y Ley 1581 (dato biométrico = sensible).

**AS-BUILT:** dimensión facial = **128** (SFace). No documentar ni implementar 512.

---

## 1. Clasificación MSPI (resumen)

| Activo | Confidencialidad | Integridad | Disponibilidad | Notas |
|--------|------------------|------------|----------------|-------|
| Vector facial de referencia | **Alta** | Alta | Media | Biométrico; no loguear en texto plano |
| Foto de enrolamiento | **Alta** | Alta | Media | Biométrico; filesystem servidor |
| Embedding por evento en log | **Alta** | Alta | Media | Auditoría de captura |
| Documento / nombres | Alta (personal) | Alta | Alta | Identidad |
| `usr_insert` / sesión | Media–Alta | Alta | Alta | Trazabilidad operativa |
| Catálogos método/entrada | Baja | Media | Alta | No sensibles |

Cifrado en reposo (E2) de fotos/vectores: **diferido** por decisión institucional — no confundir con “cumplido”.

---

## 2. Referencia facial por persona (AS-BUILT)

### `tab_personas` — columnas biométricas clave

| Columna | Tipo | Clasificación MSPI | Descripción |
|---------|------|--------------------|-------------|
| `id_persona` | NUMERIC(10) PK | Personal | Documento/persona |
| `val_patron_facial` | **VECTOR(128)** | **Biométrico — alta confidencialidad** | Embedding SFace de referencia; usado por `fun_guardar_enrolamiento_facial` / `fun_identificar_persona_por_rostro` |
| `ruta_foto_facial` | VARCHAR(500) | **Biométrico — alta confidencialidad** | Ruta relativa a la foto de enrolamiento en storage |
| `val_huella_digital` | BYTEA | Biométrico alta | Placeholder huella |
| `usr_insert` / `usr_update` | VARCHAR | Auditoría | Quién creó/actualizó (sesión real) |
| `ind_estado` | BOOLEAN | Operacional | Solo activos en identificación |

---

## 3. `tab_enrolamiento_facial` (migración / diseño temprano)

Tabla introducida en Bug 19 (`add_tab_enrolamiento_facial.sql`), alterada a **VECTOR(128)** (`alter_tab_enrolamiento_facial_vector_128.sql`), con `ruta_foto_enrolamiento` (`add_ruta_foto_enrolamiento.sql`).

| Columna | Tipo AS-BUILT | Clasificación MSPI | Descripción |
|---------|---------------|--------------------|-------------|
| `id_enrolamiento` | SERIAL PK | — | Surrogate |
| `id_persona` | NUMERIC FK → `tab_personas` | Personal | Dueño del patrón |
| `facial_embedding` | **VECTOR(128)** (antes 512) | **Biométrico — alta confidencialidad** | Vector de referencia en el diseño tabular dedicado |
| `ruta_foto_enrolamiento` | VARCHAR(500) | **Biométrico — alta confidencialidad** | Foto asociada al enrolamiento |
| `calidad_facial` | NUMERIC(5,2) | Operacional | Métrica de captura |
| `ind_activo` | BOOLEAN | Operacional | Soft-flag |
| `usr_insert` / `fec_insert` | VARCHAR / TIMESTAMP | Auditoría | Obligatorios en diseño |

**Nota de congruencia:** el runtime actual de funciones PHP/SQL consolida la referencia en `tab_personas` (ver §2). Esta tabla se documenta porque forma parte del historial de migraciones y del inventario de activos biométricos del módulo desktop.

---

## 4. `tab_log_ingresos` — columnas clave para desktop

| Columna | Tipo | Clasificación MSPI | Descripción |
|---------|------|--------------------|-------------|
| `id_ingreso` | INTEGER PK | Operacional | ID del evento |
| `id_visitante` | NUMERIC FK | Personal | Persona que ingresó |
| `fec_ingreso` / `fec_salida` | TIMESTAMP | Operacional | Ingreso abierto si iguales |
| `id_metodo_aut` | NUMERIC FK | Operacional | **1** manual … **4** facial … **5** huella — crítico para auditoría SIEM/desktop |
| `id_entrada_centro` | NUMERIC FK | Operacional | Puerta |
| `facial_embedding` | **VECTOR(128)** | **Biométrico — alta confidencialidad** | Embedding **del evento** (no sustituye la referencia por persona) |
| `url_foto_facial` | VARCHAR(500) | Biométrico alta | Evidencia por evento si aplica |
| `calidad_facial` | NUMERIC | Operacional | Calidad captura del evento |
| `usr_insert` | VARCHAR(50) | Auditoría / media-alta | **Usuario real de sesión** (ej. `porteria`) — mismo canal que la web |
| `fec_insert` | TIMESTAMP | Auditoría | Momento de registro |
| `val_datos_origen` | JSONB | Variable | Metadata QR/formulario |

Whitelist `metodo_aut` en parseo de captura debe incluir biométrico facial (`4`) — ver Bug 19.

---

## 5. Tablas de soporte (columnas mínimas)

### `tab_metodos_aut`

| Columna | Uso desktop |
|---------|-------------|
| `id_metodo_aut` | Valor enviado en `ingreso_registrar` |
| Nombre descriptivo | UI / reportes |

### `tab_entradas_centro`

| Columna | Uso desktop |
|---------|-------------|
| `id_entrada_centro` | Selección de puerta en formulario / facial |
| Nombre | Catálogo `catalogos()` |

### `tab_sesiones` / `tab_usuarios`

| Columna | Uso desktop |
|---------|-------------|
| `tab_usuarios.id_usuario` | Login |
| `tab_sesiones` + cookie `PHPSESSID` | Sesión web real (ADR-02) |

---

## 6. Reglas de tratamiento (cliente)

- Vectores y fotos: solo en RAM en el PC; tránsito HTTPS; sin dump a logs (`runtime/logs/`).
- No persistir `PHPSESSID` en archivo de texto plano.
- Consentimiento biométrico explícito en UI: **pendiente** Fase 0 / Ley 1581 (ver doc seguridad).

---

## Documentos relacionados

- ER: [`diagrama-er.md`](diagrama-er.md)
- Funciones: [`catalogo-funciones.md`](catalogo-funciones.md)
- Seguridad: [`../09-seguridad-mspi.md`](../09-seguridad-mspi.md)
- ADR dimensión: [`../adr/ADR-04-sface-128-dims.md`](../adr/ADR-04-sface-128-dims.md)
