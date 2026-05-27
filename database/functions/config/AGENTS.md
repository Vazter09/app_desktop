# AGENTS.md — database/functions/config/

## Propósito

Actualizar la configuración única del sistema almacenada en `tab_config_sistema`.

---

## Función

`fun_update_tab_config_sistema(nom_sistema, color_oscuro, color_oliva, path_logo, tokens_oscuro, tokens_claro, ..., usr)` — 29 parámetros

Actualiza la fila única (id_config = 1) con todos los parámetros del sistema.

---

## Parámetros críticos

- `nom_sistema` — nombre del sistema
- `color_oscuro`, `color_oliva` — colores corporativos (hex)
- `path_logo` — ruta relativa al logo
- `tokens_oscuro`, `tokens_claro` — JSON de tokens CSS por tema
- `modulo_registro_habilitado` — flag booleano
- `usr_registro`, `pass_registro_hash` — credenciales módulo registro standalone
- Muchos otros parámetros...

---

## Convenciones

- La tabla tiene exactamente UNA fila (id_config = 1)
- Nunca insertar nuevas filas — siempre UPDATE
- Los colores son hex strings (#RRGGBB)
- Los tokens CSS son JSON parseado por `AppConfig`

---

## Dependencias

- Depende de `_helpers/smartcset_raise.sql`
- Operan sobre `tab_config_sistema`

---

## Qué NO tocar sin entender primero

- Nunca crear más filas en `tab_config_sistema` — rompe la lógica de singleton
- El orden de parámetros es crítico — cambiar el orden rompe todas las llamadas de PHP
- Los colores deben validarse como hex válido antes de guardar
