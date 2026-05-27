# AGENTS.md — database/functions/porteria/

## Propósito

7 funciones para ingreso y salida de personas. Encapsulan toda la lógica de control de acceso físico.

---

## Funciones

1. `fun_upsert_persona_visitante` — INSERT o UPDATE en `tab_personas` (paso previo)
2. `fun_insert_log_ingreso` — registra ingreso en `tab_log_ingresos`, retorna ID
3. `fun_update_persona_tras_ingreso` — actualiza `fec_última_entrada`, suma visitas
4. `fun_registrar_ingreso_manual` — ORQUESTA las 3 anteriores (proceso atómico)
5. `fun_update_log_salida` — cierra ingreso (escribe `fec_salida`)
6. `fun_update_persona_tras_salida` — actualiza `fec_última_salida`
7. `fun_registrar_salida_manual` — busca ingreso abierto + cierra (proceso atómico)

---

## Flujo de ingreso

```
fun_registrar_ingreso_manual(documento, tipo_persona, ...) → 
    1. fun_upsert_persona_visitante() → id_persona
    2. fun_insert_log_ingreso(id_persona, ...) → id_ingreso
    3. fun_update_persona_tras_ingreso(id_persona)
    → Retorna id_ingreso
```

---

## Flujo de salida

```
fun_registrar_salida_manual(documento, ...) →
    1. Busca ingreso abierto (fec_salida = fec_ingreso)
    2. fun_update_log_salida(id_ingreso) → escribe fec_salida = CURRENT_TIMESTAMP
    3. fun_update_persona_tras_salida(id_persona)
    → Retorna OK
```

---

## Concepto de "ingreso abierto"

Un ingreso está **abierto** cuando: `fec_salida = fec_ingreso` (ambas timestamps iguales)

Al registrar salida, se actualiza: `fec_salida = CURRENT_TIMESTAMP` (timestamp actual, diferente de ingreso)

Constraint único previene 2 ingresos abiertos del mismo día para la misma persona.

---

## Dependencias

- Dependen de `_helpers/smartcset_raise.sql`
- Operan sobre `tab_personas`, `tab_log_ingresos`
- Requieren `tab_metodos_aut`, `tab_entradas_centro`, `tab_tipos_persona`

---

## Qué NO tocar sin entender primero

- La lógica de "ingreso abierto" (fec_salida = fec_ingreso) es crítica
- El constraint único debe mantenerse para prevenir dobles ingresos
- Los procesos atómicos (`fun_registrar_*_manual`) NUNCA deben dividirse en 2 funciones
