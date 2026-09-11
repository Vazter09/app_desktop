# Contrato HTTP — cliente desktop (`SmartcsetClient`)

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 6, 8  

**Fuente de código:** [`../src/smartcset_client.py`](../../src/smartcset_client.py)  
**Documento origen adaptado:** [`../07-contrato-integracion.md`](../07-contrato-integracion.md)

---

## 1. Resumen

La app de escritorio **no expone API propia**. Es un cliente HTTPS/JSON del backend SmartCSET. Toda la lógica de negocio e integridad vive en PHP + PL/pgSQL.

---

## 2. Conexión

| Parámetro | Origen | Notas |
|-----------|--------|--------|
| `base_url` | `app_config.json` | Sin barra final; ej. `https://localhost/smartcset` |
| `verify_tls` | config o resolución por host | `true` en producción; lab puede usar `false` (cert autofirmado) |
| Timeout | fijo en cliente | **15 s** por request |
| Headers | siempre | `Content-Type: application/json`, `Accept: application/json` |
| Auth | cookie | `PHPSESSID` tras `login()`; jar en memoria |

El opener **no sigue redirects 3xx** (`_NoFollowRedirectHandler`): un redirect a HTML de login se trata como error de sesión/URL.

---

## 3. Contrato de respuesta

### Éxito

```json
{ "ok": true, "data": { } }
```

El cliente **retorna solo el contenido de `data`** (o `{}` si es null).

### Error de negocio

```json
{ "ok": false, "error": "Mensaje legible en español" }
```

Lanza `SmartcsetApiError`.

### Error de conexión / transporte

Lanza `SmartcsetConnectionError` si: timeout, red, TLS inválido (con verificación activa), cuerpo no JSON, o redirect 3xx.

---

## 4. Métodos de `SmartcsetClient`

### 4.1 Sesión

| Método | HTTP | Path |
|--------|------|------|
| `login(usuario, clave)` | POST | `/routers/auth/v1/login.php` |
| `logout()` | GET | `/routers/auth/v1/logout.php` |
| `clear_cookies()` / `has_session_cookie()` | — | local |

Body login: `{"usuario", "clave", "origen": "desktop"}`.

### 4.2 Portería — consulta

| Método | HTTP | Path |
|--------|------|------|
| `ingresos_hoy()` | GET | `/routers/porteria/v1/ingreso/hoy.php` |
| `salidas_hoy()` | GET | `/routers/porteria/v1/salida/hoy.php` |
| `catalogos()` | GET | `/routers/porteria/v1/catalogos.php` |
| `ingreso_consultar(documento, tipo_doc, incluir_foto=True)` | GET | `/routers/porteria/v1/ingreso/consultar.php?...` |
| `salida_consultar(documento, tipo_doc)` | GET | `/routers/porteria/v1/salida/consultar.php?...` |

### 4.3 Portería — registro

| Método | HTTP | Path |
|--------|------|------|
| `ingreso_registrar(payload)` | POST | `/routers/porteria/v1/ingreso/registrar.php` |
| `ingreso_actualizar_captura(payload)` | POST | `/routers/porteria/v1/ingreso/actualizar_captura.php` |
| `salida_registrar(payload)` | POST | `/routers/porteria/v1/salida/registrar.php` |

`metodo_aut`: `1` manual, `2` QR, `3` barras/PDF417, `4` facial, `5` huella.

### 4.4 Biometría facial (vector **128** — SFace)

| Método | HTTP | Path |
|--------|------|------|
| `biometria_enrolar(documento, embedding, calidad_facial?, foto_base64?, tipo_doc, forzar=False)` | POST | `/routers/porteria/v1/biometria/enrolar.php` |
| `biometria_identificar(embedding, umbral_distancia?)` | POST | `/routers/porteria/v1/biometria/identificar.php` |

`embedding`: lista de **128** floats. Foto de enrolamiento en base64 JPG (Opción A: archivo en servidor).

### 4.5 Biometría huella (placeholder)

| Método | HTTP | Path |
|--------|------|------|
| `biometria_huella_enrolar(...)` | POST | `/routers/porteria/v1/biometria/huella_enrolar.php` |
| `biometria_huella_identificar(...)` | POST | `/routers/porteria/v1/biometria/huella_identificar.php` |

Sin lector hardware real en as-built; uso principal en pruebas.

### 4.6 Entradas (admin)

| Método | HTTP | Path |
|--------|------|------|
| `entrada_guardar(payload)` | POST | `/routers/entradas/v1/guardar.php` |
| `entrada_eliminar(id_entrada)` | POST | `/routers/entradas/v1/eliminar.php` |

Usuario `porteria` sin admin recibe rechazo server-side.

---

## 5. Middleware en servidor

`porteriaRequireSessionOrDevice()`:

- **Desktop:** camino sesión (`$_SESSION['id_usuario']`).
- **Móvil:** token de dispositivo — no usado por esta app.

---

## 6. Dependencias backend (fuera de `app_desktop`)

Routers bajo `backend/routers/auth|porteria|entradas/`. Servicios: `biometria_service.php`, `biometria_photo_service.php`, `ingreso_service.php`. BD: ver [`../base_de_datos/`](../base_de_datos/).

Fotos: storage servidor (`uploads/biometria/` / rutas relativas en `tab_personas.ruta_foto_facial`).

---

## 7. Errores frecuentes

| Síntoma | Causa probable |
|---------|----------------|
| Respuesta inválida / no JSON | `base_url` mal o sesión expirada (HTML login) |
| No se pudo conectar | Red, firewall, TLS |
| HTTP 403 | Sin menú portería |
| Match facial siempre falla | Dimensión ≠ 128 o sin enrolamiento |

---

## Documentos relacionados

- Ejemplos: [`ejemplos-request-response.md`](ejemplos-request-response.md)
- OpenAPI manual: [`openapi-desktop.yaml`](openapi-desktop.yaml)
- Seguridad: [`../09-seguridad-mspi.md`](../09-seguridad-mspi.md)
