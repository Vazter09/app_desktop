# AGENTS.md — src/modulos/porteria/salida/

## Propósito

Vista y procesador para el registro de salidas de personas del centro. Busca el ingreso abierto de una persona y registra el cierre con fecha/hora actual.

---

## Archivos y su función

### index.php

Formulario de registro de salida. Campos mínimos:
- Tipo de documento (dropdown)
- Número documento
- Botón "Buscar ingreso"

Tras buscar, muestra resumen del ingreso abierto (si existe):
- Ingreso# (id_ingreso)
- Hora de ingreso
- Tipo de persona
- Puerta de entrada

Tabla inferior: últimas salidas del día.

**Espera:**
- Variables `$pdo`, prepared statements de `prepare.php`
- Variable `$smartcset_asset_href` de `lib/init.php`

### procesar.php

Procesador POST. Valida que existe ingreso abierto, llama `salidaRegistrarManual()` de la lib, redirige con flash message.

**Parámetros POST:**
- `tipo_docum` — tipo de documento
- `numero_docum` — número
- `id_ingreso` — ID del ingreso a cerrar (para validar)

**Retorna:**
- Redirige a `index.php` con flash message

### consultar.php

Endpoint AJAX que busca ingreso abierto para un documento. Retorna JSON con datos del ingreso.

**Parámetros POST:**
- `tipo_docum` — tipo de documento
- `numero_docum` — número

**Retorna:**
- JSON: `{ "encontrado": true/false, "id_ingreso": ..., "fec_ingreso": ..., "tipo_persona": ..., "id_puerta": ... }` o error

---

## Flujo específico

La diferencia con ingreso es que salida valida:
1. Que la persona EXISTE en BD (buscando por documento)
2. Que tiene un ingreso ABIERTO (validando `fec_salida = fec_ingreso`)
3. No permite crear nueva salida sin ingreso abierto previo

---

## Dependencias

- Depende de `lib/init.php` que incluye `prepare.php`
- Depende de `salidaRegistrarManual()` de `lib/salidas_registro.php`
- Depende de `porteriaBuscarPersona()` de `lib/porteria_consulta.php`
- Depende de prepared statements: `$stmt_list_tipos_doc`, `$stmt_list_salidas_hoy`, `$stmt_buscar_ingreso_abierto`, `$stmt_fun_registrar_salida`
- Depende de CSS: `css/modulos_salidas.css`, `css/porteria_modos.css`
- Depende de JS: `js/salidas.js`

---

## Convenciones específicas

- La búsqueda valida que `fec_salida = fec_ingreso` (ambas iguales significa ingreso abierto)
- No se permite registrar salida sin ingreso abierto previo
- El documento se normaliza igual que en ingreso (solo dígitos)

---

## Qué NO tocar sin entender primero

- No cambiar la validación de "ingreso abierto" sin actualizar la lógica en PostgreSQL también
- No permitir registrar salida si `consultar.php` no encuentra ingreso abierto
- No asumir que un documento tiene un ingreso abierto — siempre validar en PHP
