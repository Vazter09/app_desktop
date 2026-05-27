# AGENTS.md — database/functions/_helpers/

## Propósito

Helpers de manejo de excepciones y errores de PostgreSQL. Funciones que traducen errores a mensajes legibles para el usuario en español. **DEBE desplegarse PRIMERO** antes que cualquier otra función PL/pgSQL.

---

## Archivos y su función

### smartcset_raise.sql

Librería de excepciones. Contiene 5 funciones:

**`smartcset_raise_core(msg TEXT)`**
- Lanza excepción de error de sistema
- Mensaje algo técnico que describe problema profundo
- Retorna codigo de error `P0001`

**`smartcset_raise_validacion(msg TEXT)`**
- Lanza excepción de validación de datos
- Mensaje dirigido al usuario: "Nombre debe tener 3-50 caracteres"
- Retorna código `P0001`

**`smartcset_raise_negocio(msg TEXT)`**
- Lanza excepción de regla de negocio violada
- Mensaje dirigido al usuario: "No puede haber 2 ingresos abiertos del mismo día"
- Retorna código `P0001`

**`smartcset_raise_no_encontrado(msg TEXT)`**
- Lanza excepción de recurso no encontrado
- Mensaje: "Usuario no existe", "Persona no encontrada"
- Retorna código `P0001`

**`smartcset_handle_sql_error()`**
- Captura y traduce errores SQL generados por PostgreSQL
- SQLSTATE 23505 (unique violation) → "Ya existe un registro con esos datos"
- SQLSTATE 23503 (FK violation) → "No puede eliminar porque hay registros dependientes"
- Otros SQLSTATE → mensaje genérico en español
- Retorna código `P0001`

---

## Patrón de uso en otras funciones

```sql
CREATE OR REPLACE FUNCTION fun_ejemplo() RETURNS TEXT AS $$
BEGIN
    -- Validación
    IF ... THEN
        PERFORM smartcset_raise_validacion('El campo X es requerido');
    END IF;
    
    -- Lógica
    INSERT INTO tab_usuarios ...;
    
    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN RAISE;  -- Re-lanzar error de negocio
    WHEN OTHERS THEN PERFORM smartcset_handle_sql_error();  -- Traducir otros
END;
$$ LANGUAGE plpgsql;
```

---

## Mapeo de SQLSTATE a mensajes

| SQLSTATE | Situación | Mensaje |
|---|---|---|
| P0001 | Error de negocio (nuestro) | Se propaga tal cual |
| 23505 | Unique constraint violation | "Ya existe un registro con esos datos" |
| 23503 | FK constraint violation | "No puede eliminar porque hay registros dependientes" |
| 42883 | Function not found | "Función no existe" |
| OTROS | Errores inesperados | "Ha ocurrido un error. Contacte al administrador." |

---

## Filosofía

Los mensajes NUNCA deben:
- Exponer nombres de tablas
- Exponer SQLSTATE exacto al usuario
- Revelar estructura de BD
- Incluir stack traces de SQL

Los mensajes SIEMPRE deben:
- Ser en español
- Ser legibles para usuario no-técnico
- Sugerir qué hacer ("revise que el correo sea válido")
- Ser breves (1-2 líneas)

---

## Dependencias

No depende de nada. Es la base sobre la que todo lo demás se construye.

---

## Qué NO tocar sin entender primero

- No cambiar los códigos de error (SQLSTATE 'P0001') — todo el sistema asume P0001 para errores de negocio
- No agregar más de 5 funciones aquí — mantener el enfoque en excepciones
- No cambiar los mensajes sin revisar si otros SQL los depende (grep en funciones)
- No mezclar validación (raise_validacion) con reglas de negocio (raise_negocio) — mantener clara la distinción
