# ✅ CHECKEO EXHAUSTIVO DE FUNCIONES SQL v1.3

**Fecha**: 25 de febrero de 2026  
**Objetivo**: Validar todas las funciones SQL contra el modelo de base de datos V.1.3

---

## 📊 RESUMEN EJECUTIVO

| Función | Estado | Problema | Severidad |
|---------|--------|----------|-----------|
| fun_insert_tab_usuarios | ⚠️ CRÍTICO | Parámetros no utilizados en INSERT | 🔴 ALTA |
| fun_update_tab_usuarios | ✅ OK | Correcto | ✅ |
| fun_actualizar_password | ✅ OK | Correcto | ✅ |
| fun_validar_usuario | ✅ OK | Correcto | ✅ |
| fun_validar_login | ✅ OK | Correcto | ✅ |
| fun_validar_correo | ✅ OK | Correcto | ✅ |
| fun_registrar_sesion | ✅ OK | Correcto | ✅ |
| fun_delete_tab_menus | ⚠️ ERROR | Type mismatch INT/VARCHAR | 🔴 ALTA |
| fun_insert_tab_menus | ✅ OK | Correcto (ya actualizado V.1.3) | ✅ |
| fun_update_tab_menus | ✅ OK | Correcto (ya actualizado V.1.3) | ✅ |
| fun_tab_menu_usuarios | ✅ OK | Correcto (ya actualizado V.1.3) | ✅ |
| fun_trigger_menu | 🔴 CRÍTICO | INSERT con 3 parámetros (tabla solo tiene 2) | 🔴 ALTA |
| fun_ins_novedad | ✅ OK | Correcto | ✅ |

---

## 🔴 PROBLEMAS CRÍTICOS ENCONTRADOS

### 1. **fun_insert_tab_usuarios** - Parámetros no utilizados
**Ubicación**: `scripts/fun_insert_tab_usuarios.sql`

**Problema**:
```sql
-- Recibe estos parámetros:
wind_usuario tab_usuarios.ind_usuario%TYPE,
wind_estado tab_usuarios.ind_estado%TYPE

-- Pero en INSERT siempre usa valores hardcodeados:
INSERT INTO tab_usuarios VALUES(wid_usuario,wnom_usuario,wpass_usuario,wmail_usuario,TRUE,TRUE);
--                                                                                     ^^^^  ^^^^
-- Los valores deberían ser: wind_usuario, wind_estado
```

**Impacto**: 
- Los usuarios siempre se crean como administrador (ind_usuario = TRUE)
- Los usuarios siempre se crean como activos (ind_estado = TRUE)
- No se puede crear un usuario normal o inactivo

**Severidad**: 🔴 ALTA (Falla de seguridad)

---

### 2. **fun_delete_tab_menus** - Type Mismatch
**Ubicación**: `scripts/fun_delete_tab_menus.sql`

**Problema**:
```sql
-- Firma actual:
FUNCTION fun_delete_tab_menus(p_id_menu INT)

-- Pero tab_menus.id_menu es VARCHAR:
CREATE TABLE tab_menus (
    id_menu VARCHAR PRIMARY KEY,  -- ← VARCHAR, no INT
    ...
)

-- Se compara INT con VARCHAR, puede fallar:
WHERE ind_id_padre = p_id_menu  -- INT vs VARCHAR
```

**Impacto**: 
- Casting implícito puede causar fallos silenciosos
- Comparación ineficiente
- Riesgo de comportamiento indefinido

**Severidad**: 🔴 ALTA (Error de tipado)

---

### 3. **fun_trigger_menu** - INSERT con estructura incorrecta
**Ubicación**: `scripts/fun_trigger_menu.sql`

**Problema**:
```sql
-- Intenta insertar 3 valores:
INSERT INTO tab_menu_usuarios VALUES(NEW.id_usuario,wid_menu,'Exit');
--                                   ^^^^^^^^^^^^    ^^^^^^^  ^^^^^^
--                                   id_usuario      id_menu  ??? (3 parámetro no existe)

-- Pero tab_menu_usuarios V.1.3 solo tiene 2 columnas:
CREATE TABLE tab_menu_usuarios (
    id_usuario VARCHAR REFERENCES tab_usuarios(id_usuario),
    id_menu    VARCHAR REFERENCES tab_menus(id_menu),
    PRIMARY KEY(id_usuario, id_menu)
    -- nom_programa fue removido en V.1.3
);
```

**Impacto**: 
- Trigger GENERA ERROR en INSERT
- Al crear usuario, se intenta insertar menú "Fin" pero con 3 valores
- POSTGRESQL lanzará: "ERROR: INSERT has more expressions than target columns"

**Severidad**: 🔴 CRÍTICA (Bloquea creación de usuarios)

---

## ✅ FUNCIONES CORRECTAS

### ✅ fun_update_tab_usuarios
- Todos los 5 parámetros se usan correctamente
- UPDATE actualiza todos los campos excepto id_usuario (PK)

### ✅ fun_actualizar_password
- Actualiza solo pass_usuario
- Validación IF FOUND correcta

### ✅ fun_validar_usuario
- Retorna tabla con id_usuario y nom_usuario
- Valida ind_estado = TRUE

### ✅ fun_validar_login
- Retorna tabla con estatus, mensaje, id, nombre
- Bien documentado (contraseña se valida en PHP)

### ✅ fun_validar_correo
- Valida coincidencia de usuario y email
- Retorna OK o ERROR

### ✅ fun_registrar_sesion
- INSERT con ON CONFLICT para sesiones únicas
- Actualiza token_sesion y ult_actividad

### ✅ fun_insert_tab_menus (V.1.3 actualizado)
- 4 parámetros correctos incluyendo nom_programa
- INSERT incluye nuevo campo

### ✅ fun_update_tab_menus (V.1.3 actualizado)
- 4 parámetros correctos incluyendo nom_programa
- UPDATE modifica nom_programa

### ✅ fun_tab_menu_usuarios (V.1.3 actualizado)
- 2 parámetros sin nom_programa
- Coincide con estructura V.1.3

### ✅ fun_ins_novedad
- 7 parámetros todos utilizados
- Inserción con validación TRIGGER

---

## 🔧 CORRECCIONES REQUERIDAS

### Corrección 1: fun_insert_tab_usuarios
```sql
-- ANTES:
INSERT INTO tab_usuarios VALUES(wid_usuario,wnom_usuario,wpass_usuario,wmail_usuario,TRUE,TRUE);

-- DESPUÉS:
INSERT INTO tab_usuarios VALUES(wid_usuario,wnom_usuario,wpass_usuario,wmail_usuario,wind_usuario,wind_estado);
```

### Corrección 2: fun_delete_tab_menus
```sql
-- ANTES:
CREATE OR REPLACE FUNCTION fun_delete_tab_menus(p_id_menu INT) RETURNS TEXT AS

-- DESPUÉS:
CREATE OR REPLACE FUNCTION fun_delete_tab_menus(p_id_menu tab_menus.id_menu%TYPE) RETURNS TEXT AS
```

### Corrección 3: fun_trigger_menu
```sql
-- ANTES:
INSERT INTO tab_menu_usuarios VALUES(NEW.id_usuario,wid_menu,'Exit');

-- DESPUÉS:
INSERT INTO tab_menu_usuarios VALUES(NEW.id_usuario,wid_menu);
-- El valor 'Exit' ahora está en tab_menus.nom_programa, no aquí
```

---

## 📋 CHECKLIST DE VALIDACIÓN

- [x] Revisadas todas las funciones (13 total)
- [x] Verificados tipos de datos contra V.1.3
- [x] Validadas referencias a tablas
- [x] Comprobadas columnas en INSERT/UPDATE
- [x] Verificados parámetros utilizados
- [x] Revisados triggers

---

## 🎯 PRÓXIMOS PASOS

1. ✅ **Ejecutar correcciones** en los 3 archivos identificados
2. **Probar cada función** con datos de prueba
3. **Crear usuario de prueba** para validar trigger
4. **Hacer dump de datos** si existe data importante
5. **Ejecutar migration script** completo
6. **Verificar integridad referencial**

