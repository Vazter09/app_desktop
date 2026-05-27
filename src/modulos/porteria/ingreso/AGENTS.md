# AGENTS.md — src/modulos/porteria/ingreso/

## Propósito

Vista y procesador para el registro de ingresos de personas al centro. Formulario con búsqueda de persona, selección de puerta, y opción de escáner/foto.

---

## Archivos y su función

### index.php

Formulario de registro de ingreso. Campos:
- Tipo de documento (dropdown)
- Número documento
- Tipo de persona (dropdown)
- Nombre (auto-completa vía AJAX)
- Apellidos (auto-completa vía AJAX)
- Puerta (grid de botones 1-9)
- Observaciones (textarea)
- Modo lectura (barra modos escáner/foto)

**Espera:**
- Variables `$pdo`, prepared statements de `prepare.php`
- Variable `$smartcset_asset_href` de `lib/init.php`

**Emite:**
- Formulario HTML
- Tabla de últimos ingresos del día
- Modal para modo escáner o foto

### procesar.php

Procesador POST del formulario de ingreso. Valida datos, llama `ingresoRegistrarManual()` de la lib, redirige con flash message.

**Parámetros POST:**
- `tipo_docum` — tipo de documento (CC, CE, TI, etc.)
- `numero_docum` — número del documento
- `tipo_persona` — tipo de persona (aprendiz, instructor, etc.)
- `nombre_persona` — nombre de la persona
- `apellidos_persona` — apellidos
- `id_puerta_entrada` — puerta de entrada (1-9)
- `observaciones` — observaciones opcionales
- `hid_foto_data` — foto en base64 si se capturó

**Retorna:**
- Redirige a `index.php` con flash message

### consultar.php

Endpoint AJAX que busca persona por documento y tipo. Retorna JSON con datos para auto-completar.

**Parámetros POST:**
- `tipo_docum` — tipo de documento
- `numero_docum` — número

**Retorna:**
- JSON: `{ "encontrada": true/false, "id_persona": ..., "nom_persona": ..., "apellidos": ... }` o error

---

## Dependencias

- Depende de `lib/init.php` que incluye `prepare.php`
- Depende de `ingresoRegistrarManual()` de `lib/ingresos_registro.php`
- Depende de `porteriaBuscarPersona()` de `lib/porteria_consulta.php`
- Depende de prepared statements: `$stmt_list_tipos_doc`, `$stmt_list_tipos_persona`, `$stmt_list_entradas`, `$stmt_list_ingresos_hoy`, `$stmt_buscar_persona_doc`, `$stmt_fun_registrar_ingreso`
- Depende de CSS: `css/modulos_ingresos.css`, `css/porteria_modos.css`
- Depende de JS: `js/ingresos.js`, `js/porteria-captura.js`, `js/porteria-medios.js`

---

## Convenciones específicas

- El documento se normaliza en JavaScript antes de enviar (solo dígitos)
- La búsqueda AJAX usa `consultar.php` que es un endpoint separado
- La foto se guarda como base64 en `hid_foto_data` durante el formulario, se procesa en `procesar.php`

---

## Qué NO tocar sin entender primero

- No cambiar el nombre de `consultar.php` — JavaScript lo busca por nombre exacto
- No asumir que las puertas 1-9 siempre existen — validar contra `tab_entradas_centro`
- No permitir número de documento vacío — validar en PHP y JavaScript
