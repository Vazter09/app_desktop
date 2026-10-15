# Diagrama ER — alcance app desktop

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 5, 6  

Solo tablas que el flujo desktop toca vía backend (no es el modelo completo SmartCSET).

**AS-BUILT biométrico:** la referencia facial por persona vive en  
`tab_personas.val_patron_facial` (**VECTOR(128)**) y `ruta_foto_facial`.  
`tab_enrolamiento_facial` aparece por el diseño/migraciones tempranas (Bug 19→128-d); el path PHP/PL actual (`fun_guardar_enrolamiento_facial` / `fun_identificar_persona_por_rostro`) opera sobre **`tab_personas`**. Se incluye abajo por trazabilidad documental pedida al módulo.

---

```mermaid
erDiagram
  tab_usuarios ||--o{ tab_sesiones : "abre"
  tab_usuarios ||--o{ tab_log_ingresos : "usr_insert"
  tab_personas ||--o{ tab_log_ingresos : "id_visitante"
  tab_personas ||--o{ tab_enrolamiento_facial : "id_persona (legado/mig)"
  tab_metodos_aut ||--o{ tab_log_ingresos : "id_metodo_aut"
  tab_entradas_centro ||--o{ tab_log_ingresos : "id_entrada_centro"

  tab_usuarios {
    varchar id_usuario PK
    varchar nom_usuario
    boolean ind_usuario
    boolean ind_estado
  }

  tab_sesiones {
    text id_sesion PK
    varchar id_usuario FK
    timestamp fec_inicio
    timestamp fec_fin
    timestamp ult_actividad
  }

  tab_personas {
    numeric id_persona PK
    varchar id_tipo_docum
    numeric id_tipo_persona
    varchar nom_persona
    varchar ape_persona
    vector128 val_patron_facial "AS-BUILT ref facial"
    varchar ruta_foto_facial "foto enrolamiento"
    boolean ind_estado
    varchar usr_insert
  }

  tab_enrolamiento_facial {
    serial id_enrolamiento PK
    numeric id_persona FK
    vector128 facial_embedding "mig 512→128"
    varchar ruta_foto_enrolamiento
    boolean ind_activo
    varchar usr_insert
  }

  tab_log_ingresos {
    integer id_ingreso PK
    numeric id_visitante FK
    timestamp fec_ingreso
    timestamp fec_salida
    numeric id_metodo_aut FK
    numeric id_entrada_centro FK
    vector128 facial_embedding "por evento"
    varchar usr_insert "usuario sesión"
  }

  tab_metodos_aut {
    numeric id_metodo_aut PK
    varchar nom_metodo_aut
  }

  tab_entradas_centro {
    numeric id_entrada_centro PK
    varchar nom_entrada
  }
```

---

## Lectura rápida

| Tabla | Rol para desktop |
|-------|------------------|
| `tab_usuarios` / `tab_sesiones` | Login real + cookie |
| `tab_personas` | Identidad + **vector 128** de referencia + ruta foto |
| `tab_enrolamiento_facial` | Diseño/migración facial (ver nota AS-BUILT) |
| `tab_log_ingresos` | Ingreso/salida; `id_metodo_aut` (4=facial); auditoría |
| `tab_metodos_aut` | Catálogo 1–5 |
| `tab_entradas_centro` | Puerta seleccionada en registro |

Ver: [`diccionario-de-datos.md`](diccionario-de-datos.md), [`catalogo-funciones.md`](catalogo-funciones.md).
