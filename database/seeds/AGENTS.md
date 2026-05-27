# AGENTS.md — database/seeds/

## Propósito

Scripts SQL que cargan datos iniciales de desarrollo. Se ejecutan después del schema y migraciones.

---

## Archivos

### seed_acceso_dev.sql

Datos de desarrollo del módulo de acceso. Carga:
- Tipos de documento (CC, CE, TI, PA, Sin)
- Departamentos y ciudades de Colombia
- Tipos de persona (visitante, aprendiz, instructor, funcionario, contratista)
- Métodos de autenticación (manual, QR, barras)
- Entradas del centro (puertas 1-9)
- Cadena institucional (regional, centro, sede)
- Usuarios demo: `admin.smart`, `porteria` (contraseñas en texto plano, reemplazadas por bcrypt al final)
- Una persona de prueba (visitante)

### seed_menus_admin.sql

Estructura inicial de menús del sistema:
- Menú `01` (Acceso) con submenús 0101-0103
- Menú `02` (Administración) con submenús 0201-0205
- Asignación a `admin.smart`

### script_Inserts_cset V.1.0.sql

Inserciones originales V.1.0: datos maestros nacionales (departamentos, ciudades, parámetros SENA).

### inserts_cset_v1.0_alt.sql

Variante alternativa V.1.0 con estructura similar.

---

## Flujo de data en instalación

1. Schema crea tablas vacías
2. `seed_acceso_dev.sql` carga catálogos y datos básicos
3. `seed_menus_admin.sql` carga estructura de menús
4. `setup_smartcset.sh` llama `password_hash()` de PHP para hashear contraseñas demo
   - Reemplaza contraseñas de texto plano en `tab_usuarios`
   - Solo los usuarios `admin.smart` y `porteria` se reemplazan

---

## Convenciones

- Las contraseñas en seeds están en texto plano (SOLO para desarrollo)
- El script `setup_smartcset.sh` las reemplaza con bcrypt automáticamente
- Los datos deben ser mínimos pero suficientes para que el sistema funcione
- Las ciudades/departamentos son datos reales de Colombia (DANE)

---

## Estado de seeds en setup.sh

**Incluidos:**
- `seed_acceso_dev.sql` — ejecutado siempre
- `seed_menus_admin.sql` — ejecutado siempre

**NO incluidos:**
- `script_Inserts_cset V.1.0.sql`
- `inserts_cset_v1.0_alt.sql`

---

## Qué NO tocar sin entender primero

- Las contraseñas en seeds nunca deben ser usadas en producción
- El `setup_smartcset.sh` REEMPLAZA las contraseñas con bcrypt — no dejar como texto plano
- Los datos de ciudad/departamento son referencias — no cambiar sin revisar que existan en el sistema
