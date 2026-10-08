# Backup y restauración — Alcance cliente

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 8

**Audiencia:** Soporte TI, operaciones L1/L2  
**Tipo:** Runbook de operación

---

## 1. Alcance de este runbook

Este documento cubre **solo activos del PC de portería** (cliente desktop).

| Activo | ¿Backup en este runbook? | Notas |
|--------|--------------------------|-------|
| `app_config.json` | **Sí** | URL del servidor y `verify_tls` |
| Logs locales | **Opcional** | Rotan solos; útiles para diagnóstico |
| `SmartCSET_Porteria.exe` | No (regenerable) | Se reconstruye desde el repositorio |
| Datos de portería / personas | **No** | Viven en PostgreSQL del **servidor institucional** |
| Fotos biométricas | **No** | Filesystem del servidor (`uploads/biometria/`) |
| Vectores faciales | **No** | `tab_enrolamiento_facial` en BD del servidor |

> **Importante:** el backup de base de datos, fotos de enrolamiento y auditoría de ingresos es responsabilidad de **infraestructura del servidor SmartCSET**, no del cliente de escritorio. Este runbook no sustituye los procedimientos institucionales de backup de PostgreSQL ni del filesystem web.

---

## 2. Ubicación de activos en el cliente

| Modo | Configuración | Logs |
|------|---------------|------|
| Desarrollo | `app_desktop/runtime/app_config.json` | `app_desktop/runtime/logs/smartcset_desktop.log` |
| Ejecutable | `<directorio_del_exe>/app_config.json` | `<directorio_del_exe>/logs/smartcset_desktop.log` |

Rotación de logs: 2 MiB × 5 archivos (`smartcset_desktop.log` + `.1` … `.4`).

---

## 3. Backup de configuración (`app_config.json`)

### Cuándo respaldar

- Antes de cambiar `base_url` o `verify_tls`.
- Antes de actualizar el `.exe`.
- Tras una instalación estable (copia de referencia por PC).

### Procedimiento

1. Cerrar la aplicación (botón **Salir**).
2. Copiar `app_config.json` a un medio seguro (carpeta de TI, inventario de PCs).
3. Nombrar la copia con identificación del equipo, por ejemplo:

```
app_config.porteria-pc01.2026-09-03.json
```

4. Verificar que la copia **no** contiene contraseñas (el archivo solo tiene URL y TLS).

### Contenido típico (referencia)

```json
{
  "base_url": "https://10.5.213.103/smartcset",
  "verify_tls": true
}
```

---

## 4. Backup opcional de logs

Los logs **no** deben contener documentos, embeddings ni fotos (diseño as-built). Aun así:

1. Copiar la carpeta `logs/` si se necesita evidencia de un incidente.
2. Incluir las últimas 50 líneas en tickets de escalación L2.
3. No versionar logs en el repositorio git.

Limpieza manual (Windows, junto al `.exe`):

```powershell
Remove-Item logs\smartcset_desktop.log.* -Force
```

---

## 5. Restauración en PC de reemplazo

Ante fallo del PC de portería:

1. Instalar `SmartCSET_Porteria.exe` en el PC de reemplazo (ver [`instalacion.md`](instalacion.md)).
2. Restaurar `app_config.json` desde la copia del PC anterior (misma carpeta que el `.exe`).
3. Verificar cámara USB y conectividad de red al servidor.
4. Ejecutar el checklist post-instalación de [`instalacion.md`](instalacion.md) §4.
5. Confirmar login y un registro de prueba (manual o facial).

No es necesario “restaurar BD” en el cliente: los datos siguen en el servidor.

---

## 6. Qué no restaurar desde el cliente

| Situación | Acción correcta |
|-----------|-----------------|
| Pérdida de ingresos / personas | Restaurar BD en el **servidor** (procedimiento institucional) |
| Fotos de enrolamiento corruptas | Restaurar `uploads/biometria/` en el **servidor** |
| Sesiones colgadas | Cerrar vía SIEM web o SQL en servidor (ver [`incidentes-seguridad.md`](incidentes-seguridad.md)) |
| `.exe` dañado | Regenerar build desde `packaging/build_exe.ps1` |

---

## 7. Checklist rápido

- [ ] Copia de `app_config.json` por cada PC de portería
- [ ] Inventario de qué PC apunta a qué `base_url`
- [ ] En producción: `verify_tls: true` documentado en la copia
- [ ] Tras restauración: checklist de instalación OK
- [ ] Backup de BD/fotos: confirmado con el equipo de servidor (fuera de este runbook)

---

## Documentos relacionados

- Instalación: [`instalacion.md`](instalacion.md)
- Despliegue producción: [`despliegue-produccion.md`](despliegue-produccion.md)
- Incidentes: [`incidentes-seguridad.md`](incidentes-seguridad.md)
