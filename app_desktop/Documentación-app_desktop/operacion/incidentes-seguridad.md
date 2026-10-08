# Incidentes de seguridad — App de Escritorio SGI

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 6, 7, 8

**Vínculo MSPI:** Eje 8 (seguridad en redes) + controles transversales E1–E6 aplicables al cliente.  
**Audiencia:** Soporte TI L1/L2, auditor MSPI  
**Tipo:** Runbook de operación

---

## 1. Principios

- La app maneja **datos sensibles** (identidad, biometría facial). Un incidente biométrico o de sesión tiene **mayor severidad** que un fallo operativo genérico.
- El cliente **no** almacena vectores ni fotos en disco (as-built); el riesgo principal en tránsito es TLS mal configurado (`verify_tls: false` en producción).
- La auditoría de ingresos vive en el servidor (`tab_log_ingresos`, `usr_insert` = usuario real). No hay canal paralelo invisible.

---

## 2. Clasificación rápida

| Severidad | Ejemplos | Tiempo objetivo de contención |
|-----------|----------|-------------------------------|
| Crítica | Tráfico HTTP sin TLS en prod; credenciales compartidas; sospecha de suplantación masiva | Inmediato |
| Alta | Falso positivo facial usado para ingreso; PC de portería robado con sesión abierta | < 1 h |
| Media | Sesiones colgadas; cert TLS caducado; 403 sistemático tras cambio de menú | < 4 h |
| Baja | Cámara negra; log con ERROR aislado sin impacto en datos | Turno siguiente |

---

## 3. Playbooks por síntoma (L1)

| Síntoma | Diagnóstico | Acción inmediata |
|---------|-------------|------------------|
| "No se pudo conectar" | Red o servidor caído | Ping/curl al host; contactar admin servidor |
| SSL certificate verify failed | Cert inválido con `verify_tls: true` | En **lab**: `false` temporal. En **prod**: renovar certificado — **no** desactivar TLS |
| Login OK, todo falla después | Sesión expirada / `base_url` incorrecta | Re-login; verificar que `base_url` termina en `/smartcset` |
| Identifica persona equivocada | Falso positivo facial | **Cancelar** en panel de confirmación; no registrar; escalar calibración |
| App se cierra sola | Excepción no manejada | Revisar `logs/smartcset_desktop.log`; escalar L2 |
| Formulario no carga catálogos | 403 sin menú portería | Asignar menú en `tab_menu_usuarios` (servidor) |
| Sospecha de uso de credenciales ajenas | Compartido / robado | Forzar cierre de sesión (SIEM `21103`); cambiar clave; auditar `tab_intentos_login` |

---

## 4. Controles MSPI relevantes (cliente)

| Control | Estado as-built | Acción ante incidente |
|---------|-----------------|----------------------|
| E8 — TLS | Configurable; lab suele usar `false` | Verificar `verify_tls: true` en prod; no dejar override permanente |
| E1 — Acceso | Sesión PHP + menú portería en servidor | Revocar menú / forzar logout |
| E3 — Rate limit login | Heredado del servidor | Revisar IPs bloqueadas vía SIEM institucional |
| E4 — Sesión | Logout al cerrar; cookie en memoria | Cerrar sesiones colgadas en BD |
| E6 — Uploads foto | Validación MIME en servidor | Rechazo de foto inválida es comportamiento esperado |
| E2 — Cifrado reposo fotos | Diferido institucionalmente | Incidente de fuga de fotos → escalar a servidor / SENA |

### Consentimiento biométrico (Ley 1581)

Hueco documentado: la UI **no** captura consentimiento explícito antes de enrolar. Ante queja o auditoría, escalar a política Fase 0 institucional; no improvisar texto legal en el cliente sin validación.

---

## 5. Contención — sesión y PC

### 5.1 Sesiones colgadas

```sql
SELECT id_sesion, id_usuario, fec_inicio, ind_activa
FROM tab_sesiones
WHERE id_usuario = 'porteria' AND ind_activa = true;
```

Preferir cierre desde el módulo SIEM web (**Sesiones Activas**). Si no hay acceso:

```sql
UPDATE tab_sesiones
SET ind_activa = false, fec_fin = CURRENT_TIMESTAMP
WHERE id_usuario = 'porteria' AND ind_activa = true;
```

### 5.2 PC comprometido o robado

1. Forzar cierre de todas las sesiones del usuario de portería en el servidor.
2. Cambiar contraseña del usuario afectado.
3. Revisar ingresos recientes (`id_metodo_aut = 4` y manual) en la ventana del incidente.
4. No asumir que hay vectores en el disco del PC (diseño actual: no se persisten).

---

## 6. Escalación L2 / desarrollo

Escalar cuando:

- Traceback reproducible en log
- Endpoint retorna 500 persistente
- Función SQL biométrica inexistente (`function ... does not exist`)
- Match facial sistemáticamente incorrecto tras calibración
- Sospecha de interceptación de tráfico o `verify_tls` forzado a `false` en producción

**Incluir en el ticket:**

1. Versión del `.exe` o commit de git  
2. Contenido de `app_config.json` (sin credenciales)  
3. Últimas 50 líneas de `smartcset_desktop.log`  
4. Pasos para reproducir  
5. Hora aproximada (cruzar con Apache/PHP)

---

## 7. Checklist post-incidente

- [ ] Contención aplicada (sesión / red / registro cancelado)
- [ ] Evidencia de log y config archivada
- [ ] Auditoría de `tab_log_ingresos` / intentos de login revisada
- [ ] `verify_tls` en producción confirmado en `true` (si aplica)
- [ ] Ticket cerrado con causa raíz y acción correctiva
- [ ] Si tocó biometría: notificar responsable de tratamiento de datos (Fase 0)

---

## 8. Referencias

| Documento | Ubicación |
|-----------|-----------|
| Seguridad MSPI (paquete fuente) | [`../09-seguridad-mspi.md`](../09-seguridad-mspi.md) |
| Operación (paquete fuente) | [`../10-operacion-y-mantenimiento.md`](../10-operacion-y-mantenimiento.md) |
| Consigna MSPI monorepo | [`../../../CLAUDE.md`](../../../CLAUDE.md) |
| Matriz de trazabilidad | [`../anexos/matriz-trazabilidad.md`](../anexos/matriz-trazabilidad.md) |
| Despliegue producción | [`despliegue-produccion.md`](despliegue-produccion.md) |
