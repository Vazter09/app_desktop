# AGENTS.md — database/migrations/

## Propósito

Migraciones SQL incrementales aplicadas DESPUÉS del schema base. Representan cambios evolucionarios de la BD post-instalación inicial.

---

## Lista de migraciones

Ejecutadas en este orden (según `setup_smartcset.sh`):

1. `add_tab_sesiones.sql` — crea tabla de sesiones
2. `drop_functions_void_return.sql` — limpia funciones antiguas
3. `add_menu_accesos_0203_0204.sql` — agrega menús de acceso
4. `sync_admin_menu_access.sql` — sincroniza accesos admin
5. `update_nom_programa_subfolders.sql` — actualiza rutas tras reorganización src/
6. `add_menu_registro_ingreso_0102.sql` — agrega menú registro ingreso
7. `refactor_ingreso_abierto_salida.sql` — refactoriza lógica ingreso abierto
8. `add_menu_registro_salida_0103.sql` — agrega menú registro salida
9. `add_tab_config_sistema.sql` — crea tabla configuración
10. `add_menu_config_y_registro.sql` — agrega menús config + registro completo

**AUSENTES del setup.sh (3 CRÍTICAS):**
- `update_modulos_rutas_organizadas.sql` — CRÍTICA, sin esto los menús no navegan
- `update_menu_registro_listado_admin.sql` — corrige rutas legacy `admin/registro` → `admin/personas`
- `add_unique_ingreso_persona_dia.sql` — agrega constraint único

También existe:
- `clean_log_ingresos_salidas.sql` — limpieza histórica (intencional omisión)
- `password_migrator.php` — script PHP para migrar contraseñas (ejecución única)

---

## Patrón de migración

Todas son idempotentes:
```sql
-- INSERT con ON CONFLICT
INSERT INTO tab_menus (...) VALUES (...) ON CONFLICT (id_menu) DO NOTHING;

-- ALTER TABLE con IF NOT EXISTS
ALTER TABLE tab_log_ingresos ADD COLUMN IF NOT EXISTS campo_nuevo TYPE;

-- DROP con IF EXISTS
DROP INDEX IF EXISTS idx_viejo;
```

---

## Convenciones

- Una migración = un cambio lógico (no varios cambios en un archivo)
- Nombrar descriptivamente: `add_tabla_X`, `update_ruta_Y`, `add_constraint_Z`
- NUNCA destructivas (no DROP TABLE salvo si hay DROP CASCADE apropiado)
- SIEMPRE idempotentes (seguro ejecutar 2 veces)

---

## Dependencias

- Se ejecutan DESPUÉS del schema
- Se ejecutan DESPUÉS de las funciones
- Se ejecutan ANTES de los seeds

---

## Qué NO tocar sin entender primero

- No ejecutar en orden diferente — las dependencias importan
- No hacerlas destructivas sin revisar si hay datos
- La AUSENCIA de 3 migraciones críticas es un BUG — agregarlas al array del setup script
