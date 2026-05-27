# AGENTS.md — database/

## Propósito

Directorio con toda la configuración de base de datos PostgreSQL: schema de tablas, funciones PL/pgSQL, migraciones incrementales, datos iniciales (seeds), y script de instalación completa.

---

## Estructura

```
database/
├── setup_smartcset.sh           ← Script instalador (TIENE BUGS - ver SETUP_AUDIT.md en raíz)
├── bootstrap_modulo_acceso.sql  ← Bootstrap standalone del módulo acceso
├── schema/                       ← Scripts de schema por versión
│   ├── script-BD-SMARTCSET V.1.6.sql   ← ACTIVO (usar este)
│   ├── script_BD_SMARTCSET V.1.5.sql
│   ├── script_BD_SMARTCSET V.1.4.sql
│   └── history/ ← V.1.0-V.1.3 histórico
├── functions/                    ← Funciones PL/pgSQL por dominio
│   ├── _helpers/                ← Helpers de excepciones (DESPLEGAR PRIMERO)
│   ├── acceso/                  ← Usuarios, menús, sesiones
│   │   ├── menus/
│   │   ├── usuarios/
│   │   └── sesiones/
│   ├── porteria/                ← Ingreso y salida
│   ├── config/                  ← Configuración del sistema
│   └── carga/                   ← Carga de reportes SENA
├── migrations/                   ← 15 migraciones SQL
├── seeds/                        ← Datos iniciales
└── setup_smartcset.sh
```

---

## Archivos principales

### setup_smartcset.sh

Script bash instalador completo. Flujo:
1. Lee `.env` de la raíz
2. Detecta `psql` en PATH
3. Crea BD `db_smartcset` si no existe
4. Aplica schema V.1.5 (BUG: debería ser V.1.6)
5. Deploya funciones PL/pgSQL (BUG: faltan 7 funciones)
6. Crea sequence `seq_log_ingresos`
7. Ejecuta seeds y migraciones
8. Hashea contraseñas demo con PHP bcrypt

**ADVERTENCIA:** Tiene 4 bugs documentados en `SETUP_AUDIT.md`. No ejecutar sin revisar primero.

### bootstrap_modulo_acceso.sql

Script SQL standalone para inicializar solo el módulo de acceso (usuarios, menús, sesiones) sin ejecutar el setup completo. Útil para pruebas aisladas.

---

## Convenciones de versionado de schema

- Version actual: V.1.6
- Version usada por setup.sh: V.1.5 (DESACTUALIZADA - BUG)
- Histórico: V.1.0-V.1.4 en carpeta `history/`
- Patrón: cada versión es un DROP/CREATE completo de TODAS las tablas
- No usar esquemas incrementales; cada versión redefine todo

---

## Orden de despliegue obligatorio

1. Schema (V.1.6)
2. Funciones `_helpers/` (smartcset_raise_* — PRIMERO)
3. Funciones `acceso/` (usuarios, menús, sesiones)
4. Funciones `porteria/` (ingreso, salida)
5. Funciones `config/` (configuración)
6. Funciones `carga/` (carga de reportes SENA - opcional)
7. Migraciones en orden
8. Seeds

**NUNCA cambiar este orden.** Las funciones dependen unas de otras y de las tablas.

---

## Estado actual de instalación (bugs conocidos)

Función PL/pgSQL ausentes del array FUNCS en setup.sh:
- `fun_validar_correo.sql` — crítica para recuperación de contraseña
- `fun_validar_login.sql`
- `fun_validar_usuario.sql`
- `fun_delete_perfil_usuarios.sql` (plural)
- `fun_tab_menu_usuarios.sql`
- `fun_trigger_menu.sql`
- `fun_trigger_menu_admin.sql`

Migraciones ausentes:
- `update_modulos_rutas_organizadas.sql` — CRÍTICA
- `update_menu_registro_listado_admin.sql`
- `add_unique_ingreso_persona_dia.sql`

Consultar `SETUP_AUDIT.md` en la raíz para detalles completos.

---

## Dependencias

- Todo depende de PostgreSQL 14+ corriendo y accesible
- Las migraciones dependen del schema haber sido aplicado primero
- Las funciones dependen unas de otras en el orden especificado

---

## Qué NO tocar sin entender primero

- No ejecutar `setup_smartcset.sh` sin revisar los 4 bugs de `SETUP_AUDIT.md` primero
- No cambiar el orden de despliegue de funciones — las dependencias lo requieren
- No modificar schema V.1.6 directamente — crear migraciones nuevas en lugar de eso
- No eliminar funciones existentes sin revisar si `prepare.php` las referencia
