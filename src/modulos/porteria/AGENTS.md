# AGENTS.md — src/modulos/porteria/

## Propósito

Módulo de control de acceso físico al centro SENA. Permite a la portería registrar ingresos y salidas de personas, con soporte para lectura manual, escáner de códigos de barras y captura de foto.

---

## Estructura

```
porteria/
├── ingreso/             ← Registro de ingresos
│   ├── index.php       ← Vista
│   ├── procesar.php    ← Procesador POST
│   └── consultar.php   ← Endpoint AJAX
├── salida/              ← Registro de salidas
│   ├── index.php       ← Vista
│   ├── procesar.php    ← Procesador POST
│   └── consultar.php   ← Endpoint AJAX
└── lib/                 ← Lógica compartida
    ├── init.php        ← Bootstrap del módulo
    ├── acceso_documento.php
    ├── acceso_parse_captura.php
    ├── porteria_consulta.php
    ├── porteria_foto.php
    ├── porteria_modos_ui.php
    ├── ingresos_registro.php
    └── salidas_registro.php
```

---

## Flujo de ingreso

1. Usuario portería GET a `ingreso/index.php`
2. Formulario: tipo documento, número, tipo persona, nombre/apellidos, puerta (grid de botones), observaciones, modo (escáner/foto)
3. AJAX `consultar.php` busca persona existente por documento
4. Si existe, auto-completa nombre/apellidos
5. Usuario selecciona puerta y hace click "Registrar ingreso"
6. POST a `procesar.php`
7. `procesar.php` llama `ingresoRegistrarManual()` de `lib/ingresos_registro.php`
8. `ingresoRegistrarManual()` valida, normaliza documento, verifica que no haya ingreso abierto
9. Llama `fun_registrar_ingreso_manual()` en PostgreSQL
10. PostgreSQL hace: upsert persona, insert log_ingreso, update fec_última_entrada
11. Retorna `id_ingreso`
12. Flash message, redirige a `index.php`
13. Tabla inferior auto-refresca con últimos ingresos del día

---

## Flujo de salida

1. Usuario portería GET a `salida/index.php`
2. Formulario: ingresa número documento
3. AJAX `consultar.php` busca ingreso abierto (`fec_salida = fec_ingreso`)
4. Si hay ingreso abierto, muestra: ingreso#, hora, tipo, puerta entrada
5. Usuario confirma
6. POST a `procesar.php`
7. `procesar.php` llama `salidaRegistrarManual()` de `lib/salidas_registro.php`
8. Llama `fun_registrar_salida_manual()` en PostgreSQL
9. PostgreSQL actualiza `fec_salida = CURRENT_TIMESTAMP`
10. Retorna OK
11. Flash message, tabla inferior se refresca

---

## Convenciones específicas

- Lógica de "ingreso abierto": `fec_salida = fec_ingreso` (ambas timestamps iguales)
- El constraint único `idx_log_ingreso_persona_abierto` previene 2 ingresos abiertos del mismo día para la misma persona
- Los modos UI (escáner, foto) son opcionales; modo manual siempre funciona
- El documento se normaliza quitando caracteres no-dígito, máximo 10 dígitos

---

## Dependencias

- Depende de `lib/init.php` que carga `prepare.php` y `helpers.php`
- Depende de funciones PL/pgSQL: `fun_registrar_ingreso_manual()`, `fun_registrar_salida_manual()`
- Depende de prepared statements: `$stmt_buscar_persona_doc`, `$stmt_fun_registrar_ingreso`, `$stmt_buscar_ingreso_abierto`, `$stmt_fun_registrar_salida`
- Depende de CSS: `css/modulos_ingresos.css`, `css/modulos_salidas.css`, `css/porteria_modos.css`
- Depende de JS: `js/ingresos.js`, `js/salidas.js`, `js/porteria-captura.js`, `js/porteria-medios.js`

---

## Qué NO tocar sin entender primero

- No cambiar la lógica de "ingreso abierto" sin actualizar el constraint en BD y la validación en PHP
- No asumir que hay una entrada configurada — validar que `tab_entradas_centro` tiene al menos una fila
- No permitir ingreso si no hay tipo de persona válido — validar contra `tab_tipos_persona`
- No olvidar que la foto es opcional — si `hid_foto_data` viene vacío, procesar sin guardar foto
- No cambiar el mapeo de método autenticación (1=manual, 2=QR, 3=barras) sin actualizar `tab_metodos_aut` y toda la lógica
