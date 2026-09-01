# 10 — Operación y mantenimiento

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01  
**Audiencia:** Soporte TI, operaciones L1/L2

---

## 1. Componentes operativos

| Componente | Ubicación | Descripción |
|------------|-----------|-------------|
| Ejecutable | `SmartCSET_Porteria.exe` | Aplicación principal |
| Configuración | `app_config.json` (junto al .exe o en `runtime/`) | URL servidor, TLS |
| Logs | `logs/smartcset_desktop.log` | Registro de eventos |
| Modelos ONNX | Embebidos en `.exe` o `src/motor/models/` | YuNet + SFace |
| Venv (solo dev) | `runtime/.venv/` | Entorno Python local |

---

## 2. Logs

### 2.1 Ubicación

| Modo | Ruta |
|------|------|
| Desarrollo | `app_desktop/runtime/logs/smartcset_desktop.log` |
| Ejecutable | `<directorio_del_exe>/logs/smartcset_desktop.log` |

### 2.2 Configuración

| Parámetro | Valor |
|-----------|-------|
| Nivel default | WARNING |
| Rotación | 2 MiB por archivo |
| Archivos retenidos | 5 (`smartcset_desktop.log` + `.1` … `.4`) |
| Formato | `%(asctime)s %(levelname)s [%(name)s] %(message)s` |

### 2.3 Qué se registra

| Evento | Nivel |
|--------|-------|
| Arranque (base_url, verify_tls) | WARNING |
| Errores de API | ERROR |
| Errores de conexión | ERROR |
| Excepciones no capturadas | ERROR |
| Escala responsive | INFO |

### 2.4 Qué NO se registra (por diseño)

- Números de documento
- Vectores faciales (embeddings)
- Fotos en base64
- Contraseñas

### 2.5 Modo verbose (depuración)

```bash
# Solo desarrollo
cd app_desktop/src
SMARTCSET_DEBUG=1 python main.py
```

> Nota: verificar en `app_log.py` si la variable está cableada; si no, temporalmente cambiar nivel a DEBUG en código.

---

## 3. Monitoreo

### 3.1 Salud de la aplicación (local)

| Indicador | Cómo verificar |
|-----------|----------------|
| App abre | Doble clic en `.exe` |
| Login funciona | Credenciales `porteria` |
| Cámara activa | Video en panel izquierdo |
| Sin errores recientes | Últimas líneas del log |

### 3.2 Salud del backend (servidor)

| Indicador | Comando / consulta |
|-----------|-------------------|
| Apache activo | `systemctl status apache2` |
| Endpoint responde | `curl -k https://<host>/smartcset/routers/porteria/v1/catalogos.php` |
| BD accesible | `psql -h <host> -U postgres -d db_smartcset2 -c "SELECT 1"` |
| Sesiones colgadas | `SELECT count(*) FROM tab_sesiones WHERE ind_activa = true` |

### 3.3 Auditoría de portería

```sql
-- Ingresos biométricos de hoy
SELECT li.id_log_ingreso, p.num_documento, li.fec_ingreso, li.usr_insert
FROM tab_log_ingresos li
JOIN tab_personas p ON p.id_persona = li.id_visitante
WHERE li.id_metodo_aut = 4
  AND li.fec_ingreso::date = CURRENT_DATE
ORDER BY li.fec_ingreso DESC;
```

---

## 4. Procedimientos de mantenimiento

### 4.1 Actualizar URL del servidor

1. Cerrar la aplicación (botón Salir).
2. Editar `app_config.json`:
   ```json
   {
     "base_url": "https://NUEVO_HOST/smartcset",
     "verify_tls": true
   }
   ```
3. Guardar y reabrir la app.
4. Verificar login.

### 4.2 Actualizar ejecutable

1. Generar nuevo build en máquina de desarrollo (ver [`05-manual-instalacion.md`](05-manual-instalacion.md)).
2. En PC de portería: cerrar app.
3. Reemplazar `SmartCSET_Porteria.exe`.
4. **No sobrescribir** `app_config.json` ni carpeta `logs/`.
5. Ejecutar checklist de verificación.

### 4.3 Limpiar sesiones colgadas

Si operarios cierran la app abruptamente (apagado de PC), pueden quedar sesiones en BD:

```sql
-- Ver sesiones del usuario portería
SELECT id_sesion, id_usuario, fec_inicio, ind_activa
FROM tab_sesiones
WHERE id_usuario = 'porteria' AND ind_activa = true;

-- Forzar cierre (usar módulo SIEM si está disponible, o SQL directo)
UPDATE tab_sesiones SET ind_activa = false, fec_fin = CURRENT_TIMESTAMP
WHERE id_usuario = 'porteria' AND ind_activa = true;
```

El módulo SIEM (`21103` Sesiones Activas) permite forzar cierre desde la web.

### 4.4 Limpiar logs locales

Los logs rotan automáticamente. Para limpieza manual:

```powershell
# Windows — en directorio del .exe
Remove-Item logs\smartcset_desktop.log.* -Force
```

### 4.5 Reinstalar entorno de desarrollo

```bash
rm -rf app_desktop/runtime/.venv app_desktop/runtime/.requirements.hash
cd app_desktop/src
python main.py
# bootstrap recrea venv e instala deps
```

---

## 5. Guía de incidentes (L1)

| Síntoma | Diagnóstico | Acción |
|---------|-------------|--------|
| "No se pudo conectar" | Red o servidor caído | Verificar ping/curl al host; contactar admin servidor |
| SSL certificate verify failed | Cert inválido con `verify_tls: true` | Poner `false` en lab; en prod, renovar certificado |
| Login OK, todo falla después | Sesión expirada o redirect | Re-login; verificar `base_url` termina en `/smartcset` |
| Cámara negra | Drivers / otra app usando cámara | Cerrar Teams/Zoom; reiniciar app; probar otra USB |
| "No se detectó rostro" | Umbral YuNet o iluminación | Mejorar luz; usar captura manual |
| Identifica persona equivocada | Falso positivo | Cancelar en confirmación; ajustar umbral en servidor |
| App se cierra sola | Excepción no manejada | Revisar `logs/smartcset_desktop.log` |
| Ingreso duplicado rechazado | Regla de negocio | Normal — persona ya tiene ingreso abierto hoy |
| Formulario no carga catálogos | 403 sin menú portería | Asignar menú en `tab_menu_usuarios` |

---

## 6. Escalación (L2 / desarrollo)

Escalar a desarrollo cuando:

- Error reproducible con traceback en log
- Endpoint retorna 500 persistente
- Función SQL no existe en BD (`function ... does not exist`)
- Match facial sistemáticamente incorrecto tras calibración
- Build de `.exe` falla

**Información a incluir en el ticket:**

1. Versión del `.exe` o commit de git
2. Contenido de `app_config.json` (sin credenciales)
3. Últimas 50 líneas de `smartcset_desktop.log`
4. Pasos para reproducir
5. Hora aproximada del incidente (para cruzar con logs de Apache/PHP)

---

## 7. Backup y recuperación

| Activo | ¿Backup necesario? | Notas |
|--------|-------------------|-------|
| `app_config.json` | Sí (por PC) | Copia antes de cambios |
| `SmartCSET_Porteria.exe` | No (regenerable) | Se reconstruye desde repo |
| Logs locales | Opcional | Rotan solos; útiles para diagnóstico |
| Datos de portería | **No local** | Viven en PostgreSQL del servidor — backup de BD institucional |
| Fotos biométricas | **No local** | Filesystem del servidor (`uploads/biometria/`) |

**Recuperación ante fallo del PC de portería:**

1. Instalar `.exe` en PC de reemplazo.
2. Restaurar `app_config.json` del PC anterior.
3. Verificar cámara y red.
4. Ejecutar checklist de instalación.

---

## 8. Tareas periódicas sugeridas

| Frecuencia | Tarea | Responsable |
|------------|-------|-------------|
| Diario | Verificar que app abre y login funciona | Operario (primer turno) |
| Semanal | Revisar log por errores recurrentes | TI |
| Mensual | Verificar sesiones colgadas en BD | TI / SIEM |
| Trimestral | Actualizar `.exe` si hay release | TI |
| Anual | Revisar certificado TLS del servidor | Infraestructura |
| Por evento | Actualizar URL si migra servidor | TI |

---

## 9. Contactos y referencias

| Recurso | Ubicación |
|---------|-----------|
| Documentación de entrega | [`docs/README.md`](README.md) |
| Bugs conocidos del monorepo | [`CLAUDE.md`](../../CLAUDE.md) (sección Bugs) |
| Handoff interno de ingeniería | [`HANDOFF.md`](../HANDOFF.md) |
| Suite de tests | [`08-plan-y-evidencia-pruebas.md`](08-plan-y-evidencia-pruebas.md) |

---

## Documentos relacionados

- Instalación: [`05-manual-instalacion.md`](05-manual-instalacion.md)
- Manual de usuario: [`06-manual-usuario.md`](06-manual-usuario.md)
- Seguridad: [`09-seguridad-mspi.md`](09-seguridad-mspi.md)
