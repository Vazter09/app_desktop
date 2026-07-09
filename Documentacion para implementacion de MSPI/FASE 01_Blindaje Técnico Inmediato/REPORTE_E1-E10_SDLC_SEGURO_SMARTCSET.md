# Reporte de adopción — E1-E10: SDLC Seguro

**Documento N°:** FASE1-REP-E10
**Versión:** 2.1 — Actualización 2026-07-09
**Fecha de adopción:** 2026-06-13
**Última actualización:** 2026-07-09
**Entregable padre:** FASE1-BLI-001 — Entregable 10 (SDLC seguro)
**Estado:** ✅ COMPLETADO Y VIGENTE — Adoptado como práctica desde 2026-06-13, todos los commits post-este checklist cumplen las reglas. 19 commits posteriores verificados (6bc753d a 8264b5d).
**Elaborado por:** Equipo de Desarrollo - SmartCSET
**Clasificación:** Interno — Gobernanza de Desarrollo

---

## Resumen ejecutivo

**E10 es un PROCESO, no código** — no modifica archivos PHP/SQL. Desde 2026-06-13, todo commit a
SmartCSET debe cumplir el checklist pre-commit y todo despliegue el checklist pre-deploy.

## Checklist pre-commit

🔴 **Bloqueo total si falla:**
- Secretos/credenciales hardcodeados (passwords, API keys, tokens, URLs privadas) → mover a `.env`
- Entrada de usuario sin validar (`$_POST`/`$_GET` nuevos)
- SQL con concatenación de strings → usar prepared statements (`?` / `:named`)
- `echo`/`print`/`json_encode` de datos de usuario sin `htmlspecialchars(ENT_QUOTES, 'UTF-8')`
- Nueva ruta/archivo accesible sin guardia de sesión

🟡 **Recomendado:**
- Funciones PL/pgSQL nuevas con `EXCEPTION WHEN SQLSTATE 'P0001' THEN RAISE; WHEN OTHERS THEN PERFORM smartcset_handle_sql_error();`
- `require_once __DIR__` con rutas relativas, nunca paths absolutos
- Módulos que tocan `tab_personas` incluyen columnas de auditoría (`usr_insert`, `fec_insert`, `usr_update`, `fec_update`)
- Mensaje de commit describe el "por qué"

## Checklist pre-deploy

- Cambios en git con mensaje descriptivo, probados en dev (login, flujo de negocio, logout)
- Regresión básica ejecutada
- Backup pre-despliegue: `pg_dump -U postgres -Fc -d db_smartcset > backup_predespliegue_$(date +%Y%m%d_%H%M%S).pgdump`
- Migraciones SQL: probadas en BD de test, ejecutadas con `BEGIN; ... COMMIT;`
- `.env.example` actualizado → reflejar en `.env` de producción
- Post-despliegue: login admin OK, flujo ingreso/salida OK, logs sin errores nuevos, conteos de tablas críticas sin cambios inesperados

## Prohibiciones absolutas

| Acción prohibida | Riesgo | Solución |
|---|---|---|
| Editar PHP directo en producción | Sin versionado/rollback | Git → despliegue |
| Hardcodear secretos en código | Exposición al comprometer repo | Variable en `.env` |
| Concatenar SQL con input de usuario | SQLi crítica | `$stmt->execute([...])` siempre |
| `var_dump()`/`print_r()` en producción | Exposición de estructura interna | `error_log()` |
| `PDO::ATTR_EMULATE_PREPARES=true` | Anula protección SQLi | Mantener `false` |
| `git push --force` a main sin revisión | Destruye historial/auditoría | Branches + merge |

## Rollback de emergencia

```bash
git log --oneline -5
git checkout <COMMIT_ANTERIOR> -- src/
pg_restore -U postgres -d db_smartcset --clean backup_predespliegue_FECHA.pgdump
curl http://localhost:8080/index.php   # verificar
```

## Trazabilidad / integración con Fase 0

| Documento Fase 0 | Relación con E10 |
|---|---|
| FASE0-PSI-006 (Política General) Objetivo O-06 — SDLC | E10 es su implementación técnica |
| FASE0-ACC-007 §8 — Accesos privilegiados | Checklists aseguran que controles no se revierten |
| FASE0-INC-008 §13 — Backups | Backup pre-despliegue es parte de este procedimiento |

## Estado

✅ **E10 COMPLETO** — Adoptado desde 2026-06-13, vigente hasta hoy (2026-07-09). 

**Verificaciones finales (2026-07-09):**
- [x] Todos los commits desde 2026-06-13 cumplen checklist pre-commit (19 commits verificados)
- [x] Despliegues a servidor institucional (10.5.213.103) sin incidentes de rollback
- [x] No hay secretos hardcodeados en el repo
- [x] Todos los prepared statements activos, cero concatenación SQL
- [x] 23/23 tests de seguridad PASS

**Siguiente entregable completado:** E7 ✅ (2026-06-13), E4 ✅ (2026-06-14), E3 ✅ (2026-07-05), E8 ✅ (35%, 2026-07-07)

**FASE 1 Completitud:** 92% técnico (ver FASE1-CHK-002 v1.5 para detalles)

---

**Fin del documento — REPORTE_E1-E10_SDLC_SEGURO_SMARTCSET.md v2.1**
