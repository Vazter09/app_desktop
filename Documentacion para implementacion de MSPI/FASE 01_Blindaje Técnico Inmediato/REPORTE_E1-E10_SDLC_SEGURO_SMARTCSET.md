# Reporte de adopción — E1-E10: SDLC Seguro

**Documento N°:** FASE1-REP-E10
**Versión:** 2.0 (abreviada — supersede v1.0)
**Fecha de adopción:** 2026-06-13
**Entregable padre:** FASE1-BLI-001 — Entregable 10 (SDLC seguro)
**Estado:** ✅ Adoptado como práctica desde 2026-06-13
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

✅ Adoptado desde 2026-06-13. E7 ✅ completado (2026-06-13). Siguiente entregable en el orden acordado: **E5 — Tokens anti-CSRF**.

---

**Fin del documento**
