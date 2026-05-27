# AGENTS.md — database/schema/

## Propósito

Scripts SQL que definen la estructura completa de todas las tablas de la base de datos. Cada versión es un DROP/CREATE completo, no incremental.

---

## Archivos y su versión

### script-BD-SMARTCSET V.1.6.sql

**VERSION ACTUAL - USAR ESTA**

Schema completo revisado en Mayo 2026. Incluye:
- Tablas operativas: `tab_usuarios`, `tab_personas`, `tab_menus`, `tab_menu_usuarios`, `tab_log_ingresos`, `tab_sesiones`, `tab_config_sistema`
- Tablas maestras: `tab_dptos`, `tab_ciudades`, `tab_tipos_docum`, `tab_tipos_persona`, `tab_metodos_aut`, `tab_entradas_centro`, `tab_niveles_estudio`, `tab_profesiones`
- Tablas SENA: `tab_regionales`, `tab_centros`, `tab_sedes`, `tab_programas`, `tab_fichas`, `tab_aprendices`, `tab_instructores`, etc. (~30 tablas del sistema académico)
- Tablas temporales para carga: `tab_temp_df49`, `tab_temp_pe04`, `tab_temp_df14A`, etc.

**Tamaño:** ~280 KB

**NOTA:** El script `setup_smartcset.sh` apunta a V.1.5 (BUG) en lugar de este.

### script_BD_SMARTCSET V.1.5.sql

Versión anterior, desactualizada. Usada actualmente por `setup_smartcset.sh` (BUG conocido).

### script_BD_SMARTCSET V.1.4.sql

Versión histórica anterior a V.1.5.

### history/

Carpeta con versiones históricas V.1.0, V.1.1, V.1.2, V.1.3. Documentación de evolución de schema.

---

## Patrón de versioning

Cada script sigue el mismo patrón:

```sql
-- DROP todas las tablas (y objetos dependientes)
DROP TABLE IF EXISTS tab_usuarios CASCADE;
DROP TABLE IF EXISTS tab_personas CASCADE;
-- ... (todas las tablas)

-- CREATE todas las tablas en orden de dependencias
CREATE TABLE tab_usuarios (
    id_usuario VARCHAR(30) PRIMARY KEY,
    nom_usuario VARCHAR(100) NOT NULL,
    mail_usuario VARCHAR(100) NOT NULL UNIQUE,
    pass_usuario VARCHAR(255),
    ind_usuario BOOLEAN DEFAULT FALSE,
    ind_estado BOOLEAN DEFAULT TRUE,
    usr_insert VARCHAR(30),
    fec_insert TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usr_update VARCHAR(30),
    fec_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- CREATE índices
CREATE INDEX idx_usuarios_estado ON tab_usuarios(ind_estado);

-- CREATE secuencias
CREATE SEQUENCE seq_log_ingresos START WITH 1 INCREMENT BY 1;
```

---

## Reglas de schema

- **DROP/CREATE completo** — cada script borra y recrea todo, no es incremental
- **Columnas de auditoría** — `usr_insert`, `fec_insert`, `usr_update`, `fec_update` en todas las tablas operativas
- **Constraints FK** — relaciones entre tablas especificadas
- **Índices** — creados para columnas de búsqueda frecuente
- **Sequences** — `seq_log_ingresos` para auto-incremento
- **Dominios** — tipos personalizados como `mail_personal` para correos

---

## Orden de creación de tablas

Las tablas se crean en orden de dependencias (padres primero):
1. Tablas maestras (sin FK)
2. Tablas operativas que dependen de maestras
3. Tablas de log/auditoría

---

## Dependencias

- Requiere PostgreSQL 14+
- Usa características estándar SQL + extensiones PostgreSQL comunes

---

## Qué NO tocar sin entender primero

- No modificar V.1.6 directamente — crear migraciones nuevas en `../migrations/` en lugar de eso
- No eliminar la estructura DROP/CREATE — es intencional para permitir reset completo
- No cambiar nombres de tablas sin actualizar todas las funciones PL/pgSQL que las referencia
- No cambiar tipos de columnas sin revisar funciones y aplicaciones que las usan
