# Checklist de despliegue a producción

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 7, 8

**Audiencia:** TI, infraestructura, desarrollo  
**Tipo:** Runbook de operación

---

## 1. Objetivo

Desplegar `SmartCSET_Porteria.exe` en PCs de portería del centro de formación con configuración **segura para producción**, en especial `verify_tls: true`.

---

## 2. Prerrequisitos del servidor (gate)

Antes de copiar el `.exe` a portería:

- [ ] Backend SmartCSET accesible por HTTPS en la URL institucional
- [ ] Certificado TLS del servidor **válido** para el hostname usado en `base_url`
- [ ] Extensión `vector` (pgvector) instalada
- [ ] Tabla `tab_enrolamiento_facial` y columna `ruta_foto_enrolamiento`
- [ ] Funciones biométricas desplegadas (firma correcta; vector 128 dims)
- [ ] `id_metodo_aut = 4` presente en `tab_metodos_aut`
- [ ] Directorio `uploads/biometria/` con permisos de escritura
- [ ] Usuario de portería activo con menú de portería asignado
- [ ] Suite de tests del módulo PASS contra el entorno destino (cuando sea posible)

---

## 3. Build del ejecutable

En máquina de desarrollo Windows:

```powershell
cd app_desktop
powershell -ExecutionPolicy Bypass -File packaging\build_exe.ps1
```

- [ ] Build termina sin error
- [ ] Artefacto: `app_desktop/dist/SmartCSET_Porteria.exe`
- [ ] Modelos ONNX embebidos (no faltan al identificar en prueba)

---

## 4. Configuración de producción (obligatorio)

Junto al `.exe` en el PC de portería, `app_config.json` debe quedar así (ajustar host real):

```json
{
  "base_url": "https://10.5.213.103/smartcset",
  "verify_tls": true
}
```

| Campo | Producción | Laboratorio |
|-------|------------|-------------|
| `verify_tls` | **`true`** (obligatorio) | Puede ser `false` solo con cert autofirmado |
| `base_url` | Host institucional | Host de lab |

> **Gate MSPI Eje 8:** no desplegar a producción con `verify_tls: false`. Si el certificado no valida, el fallo es de infraestructura (renovar/san), no del cliente.

Tras editar:

- [ ] Guardar JSON válido (sin barra final en `base_url`)
- [ ] Conservar backup de `app_config.json` (ver [`backup-restauracion.md`](backup-restauracion.md))
- [ ] No sobrescribir config al actualizar el `.exe`

---

## 5. Instalación en PC de portería

- [ ] Copiar `.exe` al directorio operativo acordado
- [ ] Primer arranque crea `app_config.json` y `logs/` si no existen
- [ ] Sustituir/ajustar config con valores de §4
- [ ] Webcam conectada y reconocida por Windows
- [ ] Red intranet alcanza el servidor

---

## 6. Verificación funcional (smoke)

| # | Prueba | Criterio de éxito |
|---|--------|-------------------|
| 1 | Abrir app | Sin crash |
| 2 | Login | Usuario portería autenticado |
| 3 | Cámara | Video en panel izquierdo |
| 4 | Catálogos | Tipos doc/persona/entradas visibles |
| 5 | Ingreso manual | Registro en BD |
| 6 | Facial (si hay enrolado) | Confirmación visual + registro `metodo_aut=4` |
| 7 | Salir | Logout; sin sesión colgada |
| 8 | Log | Sin ERROR crítico post-smoke |

SQL de control (servidor):

```sql
SELECT id_log_ingreso, id_metodo_aut, usr_insert, fec_insert
FROM tab_log_ingresos
WHERE usr_insert = 'porteria'
ORDER BY fec_insert DESC
LIMIT 5;
```

---

## 7. Checklist de seguridad pre-producción

- [ ] `verify_tls: true` con certificado institucional válido
- [ ] Usuario portería con menú asignado (no admin compartido innecesario)
- [ ] Logs sin documentos/vectores/fotos en texto plano
- [ ] Acceso físico al PC de portería restringido
- [ ] Consentimiento biométrico / Fase 0: estado institucional conocido (hueco UI documentado)
- [ ] Cifrado E2 fotos: estado diferido conocido (no asumir “cumplido”)

Detalle: fuente [`../09-seguridad-mspi.md`](../09-seguridad-mspi.md) y runbook [`incidentes-seguridad.md`](incidentes-seguridad.md).

---

## 8. Actualización en producción

1. Cerrar app (botón **Salir**).
2. Reemplazar solo el `.exe`.
3. **No** sobrescribir `app_config.json` ni borrar `logs/`.
4. Reabrir y repetir smoke §6.
5. Anotar fecha/versión en inventario de TI.

---

## 9. Rollback

1. Restaurar `.exe` anterior desde repositorio de artefactos de TI.
2. Restaurar `app_config.json` desde backup si se alteró.
3. Verificar login y un registro manual.
4. Abrir incidente si el fallo involucró datos o TLS (ver [`incidentes-seguridad.md`](incidentes-seguridad.md)).

---

## Documentos relacionados

- Instalación detallada: [`instalacion.md`](instalacion.md)
- Backup cliente: [`backup-restauracion.md`](backup-restauracion.md)
- Empaquetado: [`../../packaging/README.md`](../../packaging/README.md)
