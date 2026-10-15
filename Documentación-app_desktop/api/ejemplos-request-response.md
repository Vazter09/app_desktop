# Ejemplos request / response (cliente desktop)

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 6, 8  

Ejemplos concretos alineados a [`../src/smartcset_client.py`](../../src/smartcset_client.py).  
`{BASE}` = `base_url` (ej. `https://localhost/smartcset`). Vectores: **128 floats** (SFace).

---

## 1. Login

**Request**

```http
POST {BASE}/routers/auth/v1/login.php
Content-Type: application/json
Accept: application/json

{
  "usuario": "porteria",
  "clave": "Porteria2026!",
  "origen": "desktop"
}
```

**Response 200 (éxito)** — Set-Cookie: `PHPSESSID=...`

```json
{
  "ok": true,
  "data": {
    "usuario": {
      "id": "porteria",
      "nombre": "Usuario Portería",
      "admin": false
    }
  }
}
```

**Cliente Python:** `client.login("porteria", "Porteria2026!")` → retorna el objeto `data`.

**Error de negocio (ejemplo)**

```json
{
  "ok": false,
  "error": "Usuario o contraseña incorrectos."
}
```

---

## 2. Enrolar rostro

**Request** (cookie de sesión requerida)

```http
POST {BASE}/routers/porteria/v1/biometria/enrolar.php
Content-Type: application/json
Cookie: PHPSESSID=...

{
  "documento": "1234567890",
  "tipo_doc": "CC",
  "embedding": [0.01, -0.02, 0.03],
  "calidad_facial": 0.85,
  "foto_base64": "/9j/4AAQSkZJRgABAQAAAQABAAD/...",
  "forzar": false
}
```

> En producción `embedding` tiene **128** números. Arriba se abrevia.

**Response 200 (ejemplo)**

```json
{
  "ok": true,
  "data": {
    "id_persona": 1234567890,
    "ruta_foto_facial": "1234567890/1234567890_Juan.jpg"
  }
}
```

**Cliente:**  
`client.biometria_enrolar(doc, embedding_128, calidad_facial=0.85, foto_base64=jpg_b64, tipo_doc="CC", forzar=False)`

Si ya hay vector y `forzar` es false, el servidor no pisa la referencia (comportamiento de protección).

---

## 3. Identificar rostro

**Request**

```http
POST {BASE}/routers/porteria/v1/biometria/identificar.php
Content-Type: application/json
Cookie: PHPSESSID=...

{
  "embedding": [0.01, -0.02, 0.03],
  "umbral_distancia": 0.35
}
```

**Response — match**

```json
{
  "ok": true,
  "data": {
    "match": true,
    "persona": {
      "id_persona": 1234567890,
      "documento": "1234567890",
      "nombre_completo": "Juan Pérez",
      "id_tipo_persona": 2
    },
    "distancia": 0.12,
    "foto_base64": "/9j/4AAQ..."
  }
}
```

`foto_base64` es la **foto de enrolamiento guardada** (no un frame en vivo).

**Response — sin match (forma típica)**

```json
{
  "ok": true,
  "data": {
    "match": false,
    "persona": null,
    "distancia": null,
    "foto_base64": null
  }
}
```

**Cliente:** `client.biometria_identificar(embedding_128, umbral_distancia=0.35)`

---

## 4. Registrar ingreso

Tras identificación facial o captura manual/pistola.

**Request**

```http
POST {BASE}/routers/porteria/v1/ingreso/registrar.php
Content-Type: application/json
Cookie: PHPSESSID=...

{
  "documento": "1234567890",
  "tipo_doc": "CC",
  "id_tipo_persona": 2,
  "id_entrada_centro": 1,
  "metodo_aut": 4,
  "primer_nombre": "Juan",
  "primer_apellido": "Pérez",
  "embedding": [0.01, -0.02, 0.03]
}
```

| Campo | Notas |
|-------|--------|
| `metodo_aut` | `4` = biométrico facial; `1` = manual |
| `embedding` | Opcional según flujo; dimensión 128 si se envía |
| Nombres | Requeridos sobre todo en alta de visitante |

**Response 200 (ejemplo)**

```json
{
  "ok": true,
  "data": {
    "id_ingreso": 98765,
    "mensaje": "Ingreso registrado correctamente."
  }
}
```

**Cliente:** `client.ingreso_registrar(payload)`

**Error de negocio (ejemplo — ingreso abierto)**

```json
{
  "ok": false,
  "error": "La persona ya tiene un ingreso abierto hoy."
}
```

---

## 5. Encadenado típico (facial)

```text
login → biometria_identificar → (confirmación UI) → ingreso_registrar(metodo_aut=4)
     ↘ si no match / sin enrolar → biometria_enrolar → identificar de nuevo
```

Ver también: [`contrato-http.md`](contrato-http.md), [`openapi-desktop.yaml`](openapi-desktop.yaml).
