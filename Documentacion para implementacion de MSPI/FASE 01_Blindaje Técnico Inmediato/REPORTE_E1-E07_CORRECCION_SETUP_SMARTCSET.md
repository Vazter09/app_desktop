# Reporte de implementación — E1-E07: Corrección de setup_smartcset.sh

**Documento N°:** FASE1-REP-E07
**Versión:** 2.0 (abreviada — supersede v1.0)
**Fecha de elaboración:** 2026-06-13
**Entregable padre:** FASE1-BLI-001 — Entregable 7 (Corrección setup_smartcset.sh — funciones ausentes de FUNCS)
**Estado:** ✅ Completado (parcial respecto al plan original — ver pendientes)
**Elaborado por:** Equipo de Desarrollo - SmartCSET
**Clasificación:** Interno — Seguridad de la Información

---

## Resumen ejecutivo

El plan original (FASE1-BLI-001 §9) identificaba 4 funciones PL/pgSQL ausentes del array `FUNCS` de
`database/setup_smartcset.sh`. Al revisarlas:

- ✅ **3 agregadas** (`fun_validar_login`, `fun_validar_correo`, `fun_validar_usuario`, en
  `database/functions/acceso/usuarios/`), tras alinear su bloque `EXCEPTION` al patrón estándar
  `smartcset_handle_sql_error()`. Compilan sin error en BD local.
- ❌ **1 excluida** (`fun_tab_menu_usuarios.sql`) — contiene versiones **legacy** de
  `fun_insert_menu_usuarios` y `fun_delete_perfil_usuario` que ya están en `FUNCS` con mejor implementación
  (validación de existencia con `smartcset_raise_no_encontrado`, `ON CONFLICT DO NOTHING`, manejo estándar
  de errores). Agregarla habría **sobreescrito silenciosamente** las versiones seguras en cada instalación
  nueva — regresión de seguridad de severidad media, evitada bajo la consigna de Seguridad Total.

## Hallazgo adicional

Las 3 funciones `fun_validar_*` **no son llamadas actualmente desde PHP** — login y recuperación de clave
usan SQL directo (`$stmt_login`, `$stmt_valida_mail`, `$stmt_upd_pass`). Agregarlas a `FUNCS` cierra una
**brecha documental** (catálogo de acceso incompleto en el instalador) sin cambiar el comportamiento actual.

## Cambios aplicados

| Archivo | Cambio |
|---|---|
| `database/functions/acceso/usuarios/fun_validar_correo.sql` | + bloque `EXCEPTION` estándar (no tenía) |
| `database/functions/acceso/usuarios/fun_validar_login.sql` | `GET STACKED DIAGNOSTICS` + `RAISE EXCEPTION` crudo → estándar |
| `database/functions/acceso/usuarios/fun_validar_usuario.sql` | `RAISE EXCEPTION` genérico → estándar |
| `database/setup_smartcset.sh` | + 3 entradas en `FUNCS` (acceso/usuarios) |

Patrón estándar aplicado:
```sql
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN RAISE;
    WHEN OTHERS THEN PERFORM smartcset_handle_sql_error();
END;
```

## Verificación de impacto de la exclusión

`fun_tab_menu_usuarios.sql` no es referenciado por ningún `.php`/`.sh`. Las 2 funciones que define ya se
crean en `FUNCS` vía sus propios archivos (versiones mejoradas). Una instalación nueva sigue creando ambas
funciones igual — el único efecto es el riesgo de regresión evitado. El archivo queda en el repo como
código muerto/histórico, sin impacto en runtime.

## Trazabilidad normativa

| Marco | Mapeo |
|---|---|
| ISC2 CC | D5 — Security Operations (gestión de cambios) |
| ISO/IEC 27001 | A.8.32 — Gestión de cambios |
| MSPI MinTIC | Eje 7 — Seguridad en desarrollo |
| Consigna Seguridad Total | Aplicación directa: regresión de seguridad detectada antes de desplegar |

## Pendientes derivados

- Decidir si `fun_tab_menu_usuarios.sql` se elimina o se documenta como archivo histórico no desplegable.
- `fun_delete_perfil_usuarios.sql` (plural, `acceso/menus/`) — descripción no coincide con su implementación
  real; requiere análisis propio, fuera del alcance de E7.
- Actualizar `01_BLINDAJE_TECNICO_INMEDIATO_SMARTCSET.md` §9 y `AGENTS.md` de `database/functions/`.

---

**Fin del documento**
