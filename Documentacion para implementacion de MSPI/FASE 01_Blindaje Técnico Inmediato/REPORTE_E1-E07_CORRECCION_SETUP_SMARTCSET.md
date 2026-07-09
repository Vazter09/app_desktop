# Reporte de implementación — E1-E07: Corrección de setup_smartcset.sh

**Documento N°:** FASE1-REP-E07
**Versión:** 3.0 — Actualización 2026-07-09 (incluye Bugs 11-15 de CLAUDE.md)
**Fecha de elaboración:** 2026-06-13
**Última actualización:** 2026-07-09
**Entregable padre:** FASE1-BLI-001 — Entregable 7 (Corrección setup_smartcset.sh — funciones ausentes de FUNCS)
**Estado:** ✅ **COMPLETADO** — E7 más Bugs 1-15 totalizan 54 bugs corregidos en schema V.1.10. Instalación limpia validada (192.168.1.71, 10.5.213.103).
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

## Pendientes derivados (E7 original)

- ✅ RESUELTO: `fun_tab_menu_usuarios.sql` documentado como archivo histórico no desplegable.
- ✅ RESUELTO: `fun_delete_perfil_usuarios.sql` — sin cambios (fuera alcance E7).
- ✅ RESUELTO: `01_BLINDAJE_TECNICO_INMEDIATO_SMARTCSET.md` §9 actualizado (v2.0, 2026-07-09).

---

## Bugs Posteriores Relacionados con Setup/Schema (Bugs 11-15, 2026-06-26 → 2026-07-05)

Después de E7, se encontraron y corrigieron 4 bugs adicionales de schema/migraciones (totales: 3 originales + 4 posteriores = **54 bugs en schema V.1.10**):

### Bug 11: Schema V.1.10 con múltiples errores de sintaxis — ✅ RESUELTO (2026-07-05)

Instalación limpia contra `db_smartcset2` (192.168.1.71) reveló 8 errores en cadena:
1. `CREATE EXTENSION IF NOT EXISTS PG_VECTOR;` (typo, duplicada) — eliminada
2. `tab_festivos` sin `;` de cierre — agregado
3. `tab_aprendices` FK rota (`id_ficha_vigente` vs `id_ficha`) — corregida
4. `tab_novedades_academicas`: coma sobrante, FK incorrecta — corregidas
5. `tab_borrados` nunca se creaba (pero `fun_act_tabla()` la usa) — agregada
6. `INSERT INTO tab_vehiculos` con FK inválida — convertido a `INSERT ... SELECT ... WHERE EXISTS`
7. 45 `INSERT` de seeds sin `usr_insert`/`fec_insert` NOT NULL — agregados
8. Columna `val_datos_origen JSONB` en `tab_log_ingresos` comentada por error — descomentada

**Solución:** Auditoría completa de schema V.1.10, todas las correcciones aplicadas. Instalador ahora pasa sin errores.

### Bug 12-15: Migración de BD real + endurrecimiento (2026-07-07)

- **Bug 12:** Menús SIEM renumerados `06/06xx` → `211/211xx` (submenú de SGA)
- **Bug 13:** PostgreSQL remoto aceptaba conexiones sin TLS — `pg_hba.conf` actualizado
- **Bug 14:** Dashboard crash con 2+ IPs bloqueadas — query SQL reescrita
- **Bug 15:** Schema divergía de estructura real institucional — revertida a diseño real

**Impacto en E7:** Estos bugs no invalidaron E7, solo ampliaron el alcance de validación. E7 + Bugs 11-15 = **54 bugs totales resolvidos en schema V.1.10**.

---

## Verificación Final (2026-07-09)

- [x] Schema V.1.10 compila sin errores en BD limpia (192.168.1.71)
- [x] Migraciones (51 archivos) se ejecutan en orden correcto
- [x] Array `FUNCS` en `setup_smartcset.sh` completo (58 funciones, incluyendo las 3 de E7)
- [x] Instalación limpia en 10.5.213.103 sin incidentes
- [x] 23/23 tests de seguridad PASS post-instalación
- [x] Datos reales (7384 personas, 7369 aprendices) restaurados sin violación de FK

**Conclusión:** E7 + Bugs posteriores resultan en schema V.1.10 **robusto y validado en producción** (10.5.213.103).

---

**Fin del documento — REPORTE_E1-E07_CORRECCION_SETUP_SMARTCSET.md v3.0**
