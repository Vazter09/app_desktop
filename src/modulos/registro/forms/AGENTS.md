# AGENTS.md — src/modulos/registro/forms/

## Propósito

Formularios de registro por tipo de persona. Cada formulario captura datos específicos del tipo y luego inserta directamente en tablas de BD.

---

## Archivos y estructura

### persona.php

Formulario base genérico de persona. Campos comunes a todos los tipos:
- Tipo de documento
- Número de documento
- Nombres
- Apellidos
- Correo electrónico
- Teléfono
- Departamento
- Ciudad

**Uso:** heredado por otros formularios via `require_once` o como fallback.

### aprendiz.php

Formulario específico para aprendices SENA. Extiende `persona.php` con:
- Ficha de aprendizaje (lista de fichas activas)
- Programa de formación
- Modalidad de formación
- Fase de aprendizaje

### instructor.php

Formulario específico para instructores. Campos adicionales:
- Vinculación (planta/contratista)
- Área de conocimiento
- Especialidad

### funcionario.php

Formulario específico para funcionarios administrativos. Campos adicionales:
- Área de trabajo
- Cargo/puesto
- Dependencia

### contratista.php

Formulario específico para contratistas. Campos adicionales:
- Razón social (si es empresa)
- Tipo de contratista (prestador/empresa)
- Área de servicio

---

## Convención de procesamiento

**IMPORTANTE:** Estos formularios hacen INSERTs SQL directos en la BD, NO llaman funciones PL/pgSQL. Es la única área del sistema donde ocurre esto.

```php
// Flujo típico en cada formulario:
require_once __DIR__ . '/../lib/access.php';
registroRequireAccess();  // Valida sesión

// Validar POST
if ($_POST) {
    try {
        // Normalizar datos
        $data = [...];
        
        // INSERT directo en tab_personas
        $stmt = $pdo->prepare("INSERT INTO tab_personas (tipo, nombre, ...) VALUES (...) RETURNING id_persona");
        $stmt->execute([...]);
        
        // INSERT en tabla específica (tab_aprendices, tab_instructores, etc.)
        $stmt2 = $pdo->prepare("INSERT INTO tab_aprendices (id_persona, ...) VALUES (...");
        $stmt2->execute([...]);
        
        // Flash y redirige
        $_SESSION['flash_msg'] = '...';
        header('Location: index.php');
    } catch (Exception $e) {
        $error = ErrorHandler::userMessageFromException($e);
    }
}
?>
```

---

## Dependencias

- Dependen de `lib/access.php` para validación de sesión
- Dependen de `lib/catalogos.php` para opciones de dropdowns (fichas, programas, áreas, etc.)
- Dependen de `prepare.php` para `$pdo`

---

## Deuda técnica documentada

Estos formularios usan INSERTs SQL directos en lugar del patrón de funciones PL/pgSQL usado en el resto del sistema. Esto es una inconsistencia arquitectónica conocida. Idealmente, todo INSERT debería pasar por una función PL/pgSQL que encapsule la lógica de negocio.

---

## Qué NO tocar sin entender primero

- No mover a funciones PL/pgSQL sin actualizar todo el flujo de validación
- No cambiar el orden de INSERT (primero `tab_personas`, luego tabla específica) — existe dependencia FK
- No asumir que existe una ficha en `tab_fichas` para el aprendiz — validar lista en formulario
- No olvidar incluir `lib/access.php` — es crítico para validar sesión de registro
