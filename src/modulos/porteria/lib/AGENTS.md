# AGENTS.md — src/modulos/porteria/lib/

## Propósito

Librería compartida de lógica de portería. Contiene funciones de utilidad para búsqueda de personas, normalización de documentos, parsing de códigos de barras, y manejo de fotos.

---

## Archivos y su función

### init.php

Bootstrap del módulo portería. Incluye `prepare.php` con la profundidad correcta (`dirname(__DIR__, 3)/core/prepare.php`), calcula `$smartcset_asset_href` relativo a la raíz del proyecto.

**Efecto:**
- Variables globales `$pdo`, `$stmt_*` disponibles
- Variable `$smartcset_asset_href` calculada

### acceso_documento.php

Normalización y validación de documentos. Función: `accesoNormalizarDocumento(string $doc): string`

- Quita caracteres no-dígito
- Máximo 10 dígitos
- Lanza excepción si vacío o inválido

### acceso_parse_captura.php

Parser de datos capturados por escáner. Especialmente para PDF417 de cédulas colombianas.

Función: `accesoParseCaptura(string $raw): array`

- Detecta formato (PDF417, código de barras simple, manual)
- Extrae número de documento y tipo
- Retorna array con `tipo_docum`, `numero_docum`, etc.

### porteria_consulta.php

Funciones de búsqueda de personas y estado de ingresos.

Funciones:
- `porteriaBuscarPersona(PDO $pdo, string $tipo_docum, string $numero): ?array` — busca en `tab_personas`
- `porteriaConsultarAcceso(PDO $pdo, string $id_persona): array` — obtiene ingresos activos

### porteria_foto.php

Procesamiento de fotos capturadas por cámara.

Funciones:
- `porteriaGuardarFotoRegistro(string $base64, string $id_ingreso): string` — decodifica base64, guarda PNG, retorna ruta

### porteria_modos_ui.php

Partial HTML: barra de botones "Modo Escáner / Modo Foto" compartida entre ingreso y salida. Incluye:
- Botones de selección de modo
- Contenedor de video para cámara (modo foto)
- Campo oculto `hid_foto_data` para base64 de foto

### ingresos_registro.php

Función de negocio para registrar ingreso.

Función: `ingresoRegistrarManual(PDO $pdo, PDOStatement $stmt_registro, array $datos, string $usr_actual): int`

1. Normaliza documento con `accesoNormalizarDocumento()`
2. Busca persona con `porteriaBuscarPersona()`
3. Valida que no haya ingreso abierto
4. Ejecuta `$stmt_fun_registrar_ingreso` (llama PL/pgSQL)
5. Retorna `id_ingreso`

### salidas_registro.php

Función de negocio para registrar salida.

Función: `salidaRegistrarManual(PDO $pdo, PDOStatement $stmt_registro, array $datos, string $usr_actual): int`

1. Normaliza documento
2. Busca ingreso abierto con `porteriaConsultarAcceso()`
3. Valida que ingreso existe
4. Ejecuta `$stmt_fun_registrar_salida` (llama PL/pgSQL)
5. Retorna OK

---

## Convenciones específicas

- Todas las funciones de busca/validación reciben `PDO $pdo` como primer parámetro
- Las funciones de registro reciben array `$datos` con POST del formulario
- Las excepciones se lanzan con `throw new Exception()` — son capturadas en `procesar.php` y convertidas a mensajes flash
- La normalización de documento es obligatoria en TODAS las búsquedas

---

## Dependencias

- Todas dependen de `prepare.php` incluido via `init.php`
- `porteria_consulta.php` depende de prepared statements `$stmt_buscar_persona_doc`, `$stmt_buscar_ingreso_abierto`
- `ingresos_registro.php` y `salidas_registro.php` dependen de funciones PL/pgSQL en PostgreSQL

---

## Qué NO tocar sin entender primero

- No cambiar la firma de `init.php` — otros scripts lo incluyen esperando que `$pdo` y `$smartcset_asset_href` estén disponibles
- No mover estos archivos a otra carpeta sin actualizar todos los `require_once` en ingreso/ y salida/
- No asumir que el documento siempre tiene 10 dígitos — validar rango
- No omitir la normalización de documento — es crítica para búsqueda consistente
