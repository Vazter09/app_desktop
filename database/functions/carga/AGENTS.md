# AGENTS.md — database/functions/carga/

## Propósito

Procesamiento de cargas masivas de reportes SENA (DF-49, PE-04, juicios). Funciones NO incluidas en el instalador — desplegar manualmente si el módulo está activo.

---

## Funciones

1. `fun_proceso_df49` — procesa carga DF-49 SENA desde tabla temporal
2. `fun_proceso_pe04` — procesa carga PE-04 SENA desde tabla temporal
3. `fun_proceso_juicios` — procesa juicios de evaluación desde tabla temporal

---

## Patrón

Todas siguen el mismo patrón:
1. Leen datos de tabla temporal (`tab_temp_df49`, `tab_temp_pe04`, `tab_temp_df14A`, etc.)
2. Validan datos
3. Insertan en tablas estructuradas del sistema
4. Borran tabla temporal (o marcan como procesada)

---

## Estado de despliegue

**NO incluidas en setup.sh**

Desplegar manualmente SOLO si el módulo de carga SENA está activo:
```bash
psql -h localhost -U postgres -d db_smartcset -f database/functions/carga/fun_proceso_df49.sql
psql -h localhost -U postgres -d db_smartcset -f database/functions/carga/fun_proceso_pe04.sql
psql -h localhost -U postgres -d db_smartcset -f database/functions/carga/fun_proceso_juicios.sql
```

---

## Dependencias

- Dependen de `_helpers/smartcset_raise.sql`
- Dependen de tablas temporales (`tab_temp_*`) creadas por schema

---

## Qué NO tocar sin entender primero

- No son críticas para operación normal — solo si se usa carga de reportes SENA
- El patrón tabla temporal → procesamiento → tablas finales es obligatorio
