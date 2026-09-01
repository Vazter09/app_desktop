# 08 — Plan y evidencia de pruebas

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01

---

## 1. Estrategia de pruebas

| Principio | Descripción |
|-----------|-------------|
| **Sin mocks de BD** | Los tests golpean backend y PostgreSQL reales — misma política que `scripts/test_seguridad/` |
| **Limpieza garantizada** | Cada test que crea datos los elimina en `tearDown` |
| **Mismo cliente de producción** | Tests usan `SmartcsetClient` de `src/smartcset_client.py` |
| **Datos sintéticos** | Documentos de prueba generados con UUID (no CC reales del SENA) |

**Hueco conocido:** no hay CI automatizado ni tests de UI (Tkinter).

---

## 2. Precondiciones

### 2.1 Backend accesible

La variable `SMARTCSET_BASE_URL` (o default) debe apuntar a un servidor operativo:

```bash
# En .env del monorepo (raíz)
SMARTCSET_BASE_URL=https://localhost/smartcset
# o
SMARTCSET_BASE_URL=https://10.5.213.111/smartcset
```

### 2.2 Herramientas

| Herramienta | Uso |
|-------------|-----|
| Python 3.11+ | Ejecutar tests |
| `psql` en PATH | Limpieza de datos y verificación de auditoría |
| `.env` del monorepo | Credenciales BD (`DB_HOST`, `DB_NAME`, etc.) |
| Pillow | Generación de imágenes sintéticas en tests de foto |

### 2.3 Usuario de prueba

| Variable | Default en `tests/common.py` |
|----------|------------------------------|
| Usuario | `porteria` |
| Contraseña | `Porteria2026!` |

---

## 3. Ejecución

### 3.1 Suite completa de integración HTTP

```bash
cd app_desktop/tests
python -m unittest test_smartcset_client.py -v
```

**17 casos de prueba** en 4 clases.

### 3.2 Suite de parseo y validación (unitarios)

```bash
cd app_desktop/tests
python -m unittest test_scan_capture.py -v
```

**17 casos de prueba** en 3 clases.

### 3.3 Todas las pruebas

```bash
cd app_desktop/tests
python -m unittest discover -v
```

**Total: 34 casos.**

---

## 4. Inventario de pruebas — `test_smartcset_client.py`

### TestLogin (4 casos)

| Test | RF | Qué verifica |
|------|-----|--------------|
| `test_login_exitoso` | RF-01 | Login válido retorna datos de usuario |
| `test_login_clave_incorrecta` | RF-01 | Clave mala lanza `SmartcsetApiError` |
| `test_endpoint_protegido_sin_sesion` | RF-01 | Sin cookie, endpoints fallan |
| `test_relogin_desktop_sin_logout_previo` | RF-10 | Segundo login tras perder cookie funciona |

### TestPorteriaFlujoReal (4 casos)

| Test | RF | Qué verifica |
|------|-----|--------------|
| `test_catalogos_disponibles` | RF-07 | Catálogos retornan tipos y entradas |
| `test_ciclo_ingreso_y_salida` | RF-06, RF-07 | Ciclo completo manual: consultar → ingreso → salida |
| `test_entradas_crud_requiere_admin` | RF-14 | Usuario `porteria` no puede CRUD entradas |

### TestBiometriaFacial (8 casos)

| Test | RF | Qué verifica |
|------|-----|--------------|
| `test_enrolar_e_identificar_mismo_vector` | RF-03, RF-04 | Match con mismo embedding |
| `test_identificar_vector_distinto_no_matchea` | RF-03 | Vector aleatorio no matchea |
| `test_enrolar_rechaza_dimension_incorrecta` | RF-04 | Dimensión ≠ 128 rechazada |
| `test_ingreso_por_identificacion_usa_metodo_aut_biometrico` | RF-05, RF-06 | `id_metodo_aut = 4` en BD |
| `test_enrolar_con_foto_guarda_ruta_y_se_recupera_al_identificar` | RF-04 | Foto en filesystem + base64 al identificar |
| `test_enrolar_sin_foto_es_rechazado` | RF-04, E6 | Sin foto → error servidor |
| `test_enrolar_foto_invalida_es_rechazada` | RF-04, E6 | Base64 inválido rechazado |
| `test_ingreso_persona_inexistente_con_embedding_crea_novedad` | RF-06 | Flujo novedad con embedding |

### TestBiometriaHuella (3 casos)

| Test | RF | Qué verifica |
|------|-----|--------------|
| `test_ciclo_enrolar_identificar_huella` | RF-15 | Ciclo con template sintético |
| `test_ingreso_por_huella_escribe_template_en_log` | RF-15 | `metodo_aut = 5` en log |
| `test_ingreso_huella_persona_inexistente_crea_novedad` | RF-15 | Novedad con huella |

---

## 5. Inventario de pruebas — `test_scan_capture.py`

### TestFieldValidators (3 casos)

| Test | RF | Qué verifica |
|------|-----|--------------|
| `test_documento_solo_digitos_y_longitud` | RF-07 | Validación documento |
| `test_rh_y_sexo_son_basura` | RF-07 | RH no es documento |
| `test_sanear_nombre_omite_rh` | RF-07 | Nombres sin RH |
| `test_filtro_vivo_permite_espacio` | RF-07 | Filtro de teclado en vivo |

### TestScanCapturePdf417 (6 casos)

| Test | RF | Qué verifica |
|------|-----|--------------|
| `test_pdf417_no_mete_rh_en_nombres_ni_doc` | RF-08 | PDF417 cédula colombiana |
| `test_pdf417_ambos_apellidos_y_nombres` | RF-08 | Parseo nombres completos |
| `test_pdf417_tab_como_separador` | RF-08 | Separador tab |
| `test_fecha_no_es_documento` | RF-08 | Fecha no confundida con doc |
| `test_barras_solo_digitos` | RF-08 | Código barras numérico |
| `test_basura_rh_sola_no_es_documento` | RF-08 | RH solo rechazado |

### TestScanCaptureQrYBarras (8 casos)

| Test | RF | Qué verifica |
|------|-----|--------------|
| `test_qr_url_con_nuip_continuo` | RF-08 | QR con NUIP |
| `test_qr_url_digitos_dispersos_fallback_legacy` | RF-08 | Fallback legacy QR |
| `test_qr_no_roba_pdf417_con_arroba` | RF-08 | Prioridad PDF417 sobre QR |
| `test_pdf417_con_arroba_es_barras_no_qr` | RF-08 | Clasificación correcta |
| `test_payload_largo_sin_url_no_es_qr` | RF-08 | Payload largo no es QR |
| `test_barras_1d_solo_digitos_sigue_ok` | RF-08 | Barras 1D |
| `test_qr_no_acepta_solo_fecha` | RF-08 | Fecha en QR rechazada |

---

## 6. Limpieza de datos de prueba

`tests/common.py` provee:

| Función | Uso |
|---------|-----|
| `close_stale_session(usuario)` | Cierra sesiones colgadas en `tab_sesiones` |
| `delete_test_persona(documento)` | Elimina persona y datos relacionados |
| `run_psql(sql)` | Ejecuta SQL de verificación/limpieza |

Los tests de biometría también limpian fotos en:

```
frontend/web/public/uploads/biometria/{documento}/
```

---

## 7. Evidencia de ejecución

Para documentar una corrida exitosa, guardar la salida:

```bash
cd app_desktop/tests
python -m unittest discover -v 2>&1 | tee evidencia_tests_$(date +%Y%m%d).txt
```

**Resultado esperado:** 34 tests, 0 failures, 0 errors.

Ejemplo de línea de éxito:

```
Ran 34 tests in 45.123s
OK
```

---

## 8. Pruebas manuales recomendadas (no automatizadas)

| # | Escenario | Pasos | Resultado esperado |
|---|-----------|-------|-------------------|
| M1 | Login visual | Abrir app, login `porteria` | Pantalla de reconocimiento |
| M2 | Cámara en vivo | Verificar panel izquierdo | Video fluido ~30 fps |
| M3 | Identificar persona real | Persona enrolada frente a cámara | Match + confirmación + registro |
| M4 | Enrolar persona real | Documento + rostro + Enrolar | Mensaje éxito; fila en BD |
| M5 | Fallback manual | Documento sin enrolamiento | Ingreso manual exitoso |
| M6 | Pistola PDF417 | Escanear cédula | Campos rellenados |
| M7 | Logout | Botón Salir | App cierra; sesión no colgada |
| M8 | Certificado TLS prod | `verify_tls: true` contra 10.5.213.103 | Login sin error SSL |

> **Nota:** M3 y M4 requieren persona física frente a cámara — no ejecutables en CI headless.

---

## 9. Huecos de cobertura

| Área | Estado | Impacto |
|------|--------|---------|
| UI Tkinter (pantallas, botones) | Sin tests automatizados | Regresiones visuales no detectadas |
| CI/CD pipeline | Ausente | Tests no corren en cada commit |
| Cobertura de código (`coverage`) | No medida | — |
| Tests de rendimiento (latencia facial) | Ausente | — |
| Tests de empaquetado (.exe) | Manual | Build puede romperse sin detección |
| Páginas huérfanas (Inicio, Salida, Entradas) | Sin tests UI | Código muerto no verificado visualmente |

---

## 10. Integración con suite de seguridad del monorepo

La suite `scripts/test_seguridad/` del proyecto principal valida controles E1-E07 a nivel de backend. La app desktop **hereda** esos controles al usar los mismos endpoints.

Tests relevantes cruzados:

| Test monorepo | Relación con desktop |
|---------------|---------------------|
| `test_e3_rate_limiting.py` | Login desktop respeta bloqueo por IP |
| `test_e4_hardening_sesiones.py` | Sesiones en `tab_sesiones` |
| `test_e6_verificacion_uploads.py` | Validación MIME de fotos biométricas |

Ejecutar suite de seguridad del monorepo:

```bash
cd scripts/test_seguridad
python -m unittest discover -v
```

---

## Documentos relacionados

- Matriz de trazabilidad: [`11-matriz-trazabilidad.md`](11-matriz-trazabilidad.md)
- Seguridad MSPI: [`09-seguridad-mspi.md`](09-seguridad-mspi.md)
- Instalación: [`05-manual-instalacion.md`](05-manual-instalacion.md)
