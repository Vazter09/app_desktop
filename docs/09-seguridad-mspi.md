# 09 — Seguridad y cumplimiento MSPI

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01

---

## 1. Marco normativo aplicable

| Marco | Aplicación a esta app |
|-------|----------------------|
| **MSPI (MinTIC)** | Ejes 3, 5, 6, 7, 8 — datos sensibles de identidad y biometría |
| **Ley 1581 de 2012** | Tratamiento de datos personales; dato biométrico = sensible |
| **Fase 0 SmartCSET** | Políticas de tratamiento, inventario de activos, matriz de riesgos |
| **Fase 1 — Blindaje técnico** | Entregables E1-E10 aplicables al cliente desktop |
| **OWASP Top 10** | Mitigaciones heredadas del backend + controles locales |

La app de escritorio **no está exenta** de MSPI por ser desktop — misma consigna obligatoria que backend/web desde 2026-07-09.

---

## 2. Clasificación de datos

| Dato | Clasificación | Flujo en app | Almacenamiento |
|------|---------------|--------------|----------------|
| Usuario/contraseña | Credencial | Solo en tránsito (HTTPS POST login) | No persistido localmente |
| Cookie PHPSESSID | Token de sesión | Memoria (`CookieJar`) | No en disco plano |
| Documento de identidad | Personal | Formulario + payloads HTTP | BD servidor |
| Vector facial (128 floats) | **Biométrico sensible** | Calculado en RAM; enviado HTTPS | `tab_enrolamiento_facial` |
| Foto de enrolamiento | **Biométrico sensible** | Base64 en tránsito; mostrada en UI | Filesystem servidor |
| Template huella | **Biométrico sensible** | Placeholder sintético | `tab_personas.val_huella_digital` |
| Logs de aplicación | Operacional | Sin documentos/vectores/fotos | `runtime/logs/` |

---

## 3. Los 5 Pilares — evaluación

| Pilar | Estado | Evidencia |
|-------|--------|-----------|
| **Coherencia** | ✅ | Mismos endpoints, `metodo_aut`, patrones que web |
| **Congruencia** | ✅ | Mismas reglas de ingreso único, catálogos, permisos |
| **Funcionalidad** | ✅ | Ciclo facial + manual probado end-to-end |
| **Estabilidad** | ✅ | Fallback manual; hooks de excepción global |
| **Seguridad Total** | ⚠️ | TLS configurable; E2 y consentimiento pendientes |

---

## 4. Mapeo entregables Fase 1 (E-tasks)

### E1 — Control de acceso

| Control | Implementación | Estado |
|---------|----------------|--------|
| A01 Broken Access Control | Sesión PHP real; servidor valida menú portería | ✅ |
| A02 Cryptographic Failures | TLS en tránsito app↔servidor | ⚠️ Desactivable en lab |
| A03 Injection | App no arma SQL; validación en servidor | ✅ |

**Nota:** El diseño de motor biométrico en proceso HTTPS loopback (E1-A02 extendido) **no está implementado**.

### E2 — Cifrado en reposo

| Activo | Estado |
|--------|--------|
| Vectores en `tab_enrolamiento_facial` | Sin cifrado adicional (pgvector plano) |
| Fotos en `uploads/biometria/` | JPG plano en filesystem |
| Cache local de fotos | No implementado |

**Decisión institucional (2026-07-09):** cifrado E2 de fotos diferido al SENA, no en este ciclo de desarrollo.

### E3 — Rate limiting

| Vector | Control | Estado |
|--------|---------|--------|
| Fuerza bruta login | `fun_verificar_bloqueo_ip` en servidor | ✅ Heredado |
| Fuerza bruta identificación facial | Sin límite específico por dispositivo | 🔲 Evaluar en implementación |

### E4 — Hardening de sesiones

| Control | Implementación | Estado |
|---------|----------------|--------|
| Logout al cerrar app | `main.py` → `client.logout()` | ✅ |
| Cookie en memoria | `http.cookiejar` | ✅ |
| Timeout de sesión | Heredado del servidor (`SESSION_TIMEOUT`) | ✅ |
| Indicador visual de sesión | Sin countdown en topbar | 🔲 Pendiente |

### E5 — CSRF

No aplica directamente — la app no usa formularios HTML con tokens CSRF. Comunicación JSON con cookie de sesión; el servidor valida origen de sesión.

### E6 — Verificación de uploads

| Control | Implementación | Estado |
|---------|----------------|--------|
| Validación MIME real (`finfo`) | `BiometriaPhotoService` en servidor | ✅ |
| Whitelist JPEG/PNG/WebP | Servidor rechaza otros formatos | ✅ |
| Test rechazo foto inválida | `test_enrolar_foto_invalida_es_rechazada` | ✅ |

### E8 — Hardening de red / TLS

| Canal | TLS | Verificación certificado |
|-------|-----|--------------------------|
| App → Backend | HTTPS obligatorio | `verify_tls` configurable |
| App → Motor local | N/A (in-process) | — |
| PHP → PostgreSQL | `DB_SSLMODE=require` en servidor | Responsabilidad infra |

**Riesgo documentado:** el seed de portería (`app_config.porteria.json`) usa `"verify_tls": false` para el servidor de laboratorio con certificado autofirmado. En producción institucional con certificado válido, debe configurarse `"verify_tls": true`.

### E10 — SDLC seguro

| Práctica | Estado |
|----------|--------|
| Tests automatizados sin mocks | ✅ 34 casos |
| PEP8 / ruff | ✅ Política monorepo |
| Sin secretos en repo | ✅ |
| CI automatizado | 🔲 Ausente |
| Versionado semver | 🔲 Ausente |

### E11 — Mini SIEM

Los ingresos/salidas registrados por la app quedan en `tab_log_ingresos` con `usr_insert` = usuario real de sesión — **mismo canal de auditoría que la web**, sin canal paralelo invisible.

---

## 5. MSPI Fase 0 — obligaciones pendientes

| Documento Fase 0 | Extensión requerida para biometría desktop | Estado |
|------------------|-------------------------------------------|--------|
| Política de tratamiento de datos | Apartado "datos biométricos / app escritorio SGI" | 🔲 Pendiente institucional |
| Inventario de activos | `tab_enrolamiento_facial`, vectores, fotos = alta confidencialidad | 🔲 Pendiente |
| Matriz de riesgos | Suplantación biométrica, robo de PC con webcam | 🔲 Pendiente |
| Control acceso físico | PC de portería como activo de seguridad | 🔲 Pendiente |
| Gestión de incidentes | Incidentes biométricos = mayor severidad | 🔲 Pendiente |

### Consentimiento biométrico (Ley 1581)

**Hueco crítico:** la app **no muestra** aviso ni captura consentimiento explícito antes de enrolar un rostro. El flujo de enrolamiento asume autorización implícita.

**Recomendación:** agregar modal de consentimiento con registro en BD (columna o tabla de consentimiento) antes de producción con personas reales.

---

## 6. Controles de seguridad en el cliente

### 6.1 Transporte

- HTTPS obligatorio hacia el backend.
- `ssl.create_default_context()` cuando `verify_tls=true`.
- No se desactiva verificación silenciosamente — requiere override explícito en JSON.

### 6.2 Autenticación

- Login real de usuario SmartCSET (no token compartido).
- Cookie `PHPSESSID` no escrita a disco en texto plano.
- Logout explícito al cerrar aplicación.

### 6.3 Procesamiento biométrico local

- Vector calculado en memoria; **no persistido en disco** del PC.
- Modelos ONNX embebidos en el ejecutable (no descarga en runtime).
- Motor in-process: no expuesto a red local.

### 6.4 Logging

- Nivel default: WARNING.
- No se loguean documentos, embeddings ni fotos en texto plano.
- Rotación: 2 MiB × 5 archivos.

### 6.5 Validación de entrada

- `field_validators.py`: sanitización de documento y nombres.
- `scan_capture.py`: parseo defensivo de payloads de pistola.
- Servidor valida todo payload de registro (defensa en profundidad).

### 6.6 Confirmación antes de registrar (E1 + E4)

`IdentificationConfirmationPanel` exige revisión visual de foto y datos antes de registrar ingreso/salida biométrico. Auto-registro a los 2,5 s si el operario no cancela.

---

## 7. Amenazas y mitigaciones

| Amenaza | Impacto | Mitigación actual | Residual |
|---------|---------|-------------------|----------|
| Suplantación por falso positivo facial | Alto | Umbral coseno 0.35 + confirmación visual | Calibrar con datos reales |
| Intercepción tráfico HTTPS | Alto | TLS (si `verify_tls=true`) | `false` en lab |
| Robo de PC de portería | Alto | Sesión expira; vector no en disco | Acceso físico al equipo |
| Fuga de fotos en filesystem servidor | Alto | Permisos de directorio web | Sin cifrado E2 |
| Ingreso duplicado rápido | Medio | Reglas servidor | Sin rate limit local |
| Sesión colgada | Bajo | Logout al cerrar + `close_stale_session` en tests | — |

---

## 8. Checklist pre-producción (seguridad)

- [ ] `verify_tls: true` con certificado institucional válido
- [ ] Usuario portería activo con menú asignado
- [ ] Funciones SQL de biometría desplegadas (firma 4-arg, vector 128)
- [ ] Migración `ruta_foto_enrolamiento` aplicada
- [ ] Consentimiento biométrico implementado en UI
- [ ] Inventario de activos actualizado (Fase 0)
- [ ] Matriz de riesgos actualizada con biometría
- [ ] Suite de tests PASS contra servidor de producción
- [ ] Logs verificados: sin datos sensibles en texto plano
- [ ] PC de portería con acceso físico restringido

---

## 9. Referencias internas

| Documento | Ubicación |
|-----------|-----------|
| Reglas de arquitectura (diseño) | [`REGLAS_APP_ESCRITORIO_SGI.md`](../REGLAS_APP_ESCRITORIO_SGI.md) |
| Consigna MSPI obligatoria | [`CLAUDE.md`](../../CLAUDE.md) (raíz monorepo) |
| Tests de seguridad E1-E07 | [`scripts/test_seguridad/`](../../scripts/test_seguridad/) |
| Documentación MSPI SENA | `Documentacion para implementacion de MSPI/` |

---

## Documentos relacionados

- Matriz de trazabilidad: [`11-matriz-trazabilidad.md`](11-matriz-trazabilidad.md)
- Contrato API: [`07-contrato-integracion.md`](07-contrato-integracion.md)
- Operación: [`10-operacion-y-mantenimiento.md`](10-operacion-y-mantenimiento.md)
