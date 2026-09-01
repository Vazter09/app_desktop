# 07 — Contrato de integración (API HTTP)

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01

---

## 1. Resumen

La app de escritorio consume el backend SmartCSET existente mediante **HTTPS** y **JSON**. No expone API propia; actúa exclusivamente como **cliente**.

**Implementación:** [`src/smartcset_client.py`](../src/smartcset_client.py) — clase `SmartcsetClient`.

---

## 2. Configuración de conexión

| Parámetro | Origen | Default desarrollo | Default empaquetado |
|-----------|--------|-------------------|---------------------|
| `base_url` | `app_config.json` | `https://localhost/smartcset` | `https://10.5.213.111/smartcset` |
| `verify_tls` | `app_config.json` o auto | `true` (excepto localhost) | `false` en seed de portería |

**Timeout:** 15 segundos por request.

**Headers enviados en todas las peticiones:**
```
Content-Type: application/json
Accept: application/json
```

**Autenticación:** cookie `PHPSESSID` obtenida tras login exitoso. El servidor valida sesión en cada endpoint protegido.

---

## 3. Contrato de respuesta estándar

### Éxito

```json
{
  "ok": true,
  "data": { }
}
```

El cliente retorna el contenido de `data` (o `{}` si es null).

### Error de negocio

```json
{
  "ok": false,
  "error": "Mensaje legible en español"
}
```

Lanza `SmartcsetApiError` con el mensaje de `error`.

### Error de conexión

Lanza `SmartcsetConnectionError` si:
- Timeout o red inalcanzable
- TLS inválido (con `verify_tls=true`)
- Respuesta no JSON
- Redirect 3xx (no se siguen automáticamente)

---

## 4. Endpoints consumidos

### 4.1 Autenticación

| Método cliente | HTTP | Path | Body / Query |
|----------------|------|------|--------------|
| `login(usuario, clave)` | POST | `/routers/auth/v1/login.php` | `{"usuario", "clave", "origen": "desktop"}` |
| `logout()` | GET | `/routers/auth/v1/logout.php` | — |

**Respuesta login (`data`):**
```json
{
  "usuario": {
    "id": "porteria",
    "nombre": "Usuario Portería",
    "admin": false
  }
}
```

---

### 4.2 Portería — consultas

| Método cliente | HTTP | Path |
|----------------|------|------|
| `ingresos_hoy()` | GET | `/routers/porteria/v1/ingreso/hoy.php` |
| `salidas_hoy()` | GET | `/routers/porteria/v1/salida/hoy.php` |
| `catalogos()` | GET | `/routers/porteria/v1/catalogos.php` |
| `ingreso_consultar(doc, tipo_doc, incluir_foto=True)` | GET | `/routers/porteria/v1/ingreso/consultar.php?documento=&tipo_doc=&incluir_foto=1` |
| `salida_consultar(doc, tipo_doc)` | GET | `/routers/porteria/v1/salida/consultar.php?documento=&tipo_doc=` |

**Respuesta `catalogos` (`data`):**
```json
{
  "tipos_doc": [...],
  "tipos_persona": [...],
  "entradas": [...]
}
```

---

### 4.3 Portería — registro

| Método cliente | HTTP | Path |
|----------------|------|------|
| `ingreso_registrar(payload)` | POST | `/routers/porteria/v1/ingreso/registrar.php` |
| `ingreso_actualizar_captura(payload)` | POST | `/routers/porteria/v1/ingreso/actualizar_captura.php` |
| `salida_registrar(payload)` | POST | `/routers/porteria/v1/salida/registrar.php` |

**Campos típicos del payload de ingreso:**
```json
{
  "documento": "1234567890",
  "tipo_doc": "CC",
  "id_tipo_persona": 2,
  "id_entrada_centro": 1,
  "metodo_aut": 4,
  "embedding": [0.1, 0.2, ...],
  "primer_nombre": "Juan",
  "primer_apellido": "Pérez"
}
```

| `metodo_aut` | Significado |
|--------------|-------------|
| 1 | Manual |
| 2 | QR |
| 3 | Código de barras / PDF417 |
| 4 | Biométrico facial |
| 5 | Huella dactilar |

---

### 4.4 Biometría facial

| Método cliente | HTTP | Path |
|----------------|------|------|
| `biometria_enrolar(doc, embedding, calidad, foto_b64, tipo_doc, forzar)` | POST | `/routers/porteria/v1/biometria/enrolar.php` |
| `biometria_identificar(embedding, umbral?)` | POST | `/routers/porteria/v1/biometria/identificar.php` |

**Payload enrolar:**
```json
{
  "documento": "1234567890",
  "tipo_doc": "CC",
  "embedding": [128 floats],
  "calidad_facial": 0.85,
  "foto_base64": "<base64 JPG>",
  "forzar": false
}
```

**Payload identificar:**
```json
{
  "embedding": [128 floats],
  "umbral_distancia": 0.35
}
```

**Respuesta identificar con match (`data`):**
```json
{
  "match": true,
  "persona": {
    "id_persona": 12345,
    "documento": "1234567890",
    "nombre_completo": "Juan Pérez",
    "id_tipo_persona": 2
  },
  "distancia": 0.12,
  "foto_base64": "<base64 JPG del enrolamiento>"
}
```

---

### 4.5 Biometría huella (placeholder)

| Método cliente | HTTP | Path |
|----------------|------|------|
| `biometria_huella_enrolar(doc, template_b64, calidad?)` | POST | `/routers/porteria/v1/biometria/huella_enrolar.php` |
| `biometria_huella_identificar(template_b64)` | POST | `/routers/porteria/v1/biometria/huella_identificar.php` |

> **Nota:** La app genera templates sintéticos en `motor/huella.py`. Sin lector hardware real, estos endpoints solo se usan en pruebas automatizadas.

---

### 4.6 Entradas / puertas (admin)

| Método cliente | HTTP | Path |
|----------------|------|------|
| `entrada_guardar(payload)` | POST | `/routers/entradas/v1/guardar.php` |
| `entrada_eliminar(id_entrada)` | POST | `/routers/entradas/v1/eliminar.php` |

Requiere usuario administrador en el servidor. Usuario `porteria` recibe rechazo (verificado en tests).

---

## 5. Dependencias de backend (referencia)

Estos componentes **no viven en `app_desktop`** pero son necesarios para que la app funcione:

### Routers PHP

```
backend/routers/auth/v1/login.php
backend/routers/auth/v1/logout.php
backend/routers/porteria/v1/ingreso/*.php
backend/routers/porteria/v1/salida/*.php
backend/routers/porteria/v1/catalogos.php
backend/routers/porteria/v1/biometria/*.php
backend/routers/entradas/v1/*.php
```

### Servicios PHP

```
backend/services/porteria/biometria_service.php
backend/services/porteria/biometria_photo_service.php
backend/services/porteria/biometria_huella_service.php
backend/services/porteria/ingreso_service.php
```

### Base de datos

| Tabla / función | Uso |
|-----------------|-----|
| `tab_enrolamiento_facial` | Vectores de referencia (VECTOR 128) + ruta foto |
| `tab_log_ingresos` | Registro ingresos/salidas |
| `tab_personas` | Datos de personas |
| `tab_metodos_aut` | Catálogo métodos (1-5) |
| `tab_entradas_centro` | Puertas del centro |
| `tab_sesiones` | Sesiones activas |
| `fun_guardar_enrolamiento_facial` | Persistir enrolamiento |
| `fun_identificar_persona_por_rostro` | Búsqueda pgvector HNSW |
| `fun_registrar_ingreso_manual` | Registro ingreso |
| Funciones de salida | Registro salida |

### Filesystem

```
frontend/web/public/uploads/biometria/{id_persona}/{id}_{nombre}.jpg
```

---

## 6. Middleware de acceso en servidor

Los endpoints de portería usan `porteriaRequireSessionOrDevice()`:

- **Camino web (esta app):** valida `$_SESSION['id_usuario']`.
- **Camino device (app móvil):** valida token de dispositivo — **no usado por desktop**.

---

## 7. Ejemplo de uso (Python)

```python
from smartcset_client import SmartcsetClient

client = SmartcsetClient("https://localhost/smartcset", verify_tls=False)
client.login("porteria", "Porteria2026!")

catalogos = client.catalogos()
persona = client.ingreso_consultar("1234567890", "CC")
resultado = client.biometria_identificar(embedding_128_dims)

client.logout()
```

---

## 8. Errores comunes

| Síntoma | Causa probable | Acción |
|---------|----------------|--------|
| "Respuesta inválida del servidor" | URL incorrecta o sesión expirada (redirect a login HTML) | Verificar `base_url` y re-login |
| "No se pudo conectar" | Servidor caído, firewall, TLS | Verificar red y `verify_tls` |
| "Error HTTP 403" | Usuario sin permiso de menú portería | Asignar menú en `tab_menu_usuarios` |
| "function ... does not exist" | Función SQL no desplegada | Ejecutar migraciones y FUNCS en BD |
| Match facial siempre falla | Vector 128 vs tabla con 512, o sin enrolamiento | Verificar dimensión y datos en `tab_enrolamiento_facial` |

---

## Documentos relacionados

- Arquitectura: [`03-arquitectura.md`](03-arquitectura.md)
- Pruebas de integración: [`08-plan-y-evidencia-pruebas.md`](08-plan-y-evidencia-pruebas.md)
- Instalación: [`05-manual-instalacion.md`](05-manual-instalacion.md)
