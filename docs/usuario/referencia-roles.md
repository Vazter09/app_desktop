# Referencia: roles en el cliente de escritorio

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 6, 7

**Audiencia:** Operario, administrador, TI  
**Tipo:** Referencia Diátaxis

---

## Alcance

Esta referencia describe **qué hace cada rol respecto a la app de escritorio**. No inventa ni enumera menús de la aplicación web: los permisos reales de menú viven en el servidor (`tab_menu_usuarios`) y se validan en cada request.

La UI actual del desktop **no tiene sidebar**: tras el login solo se muestra la pantalla unificada de ingreso/reconocimiento.

---

## Operario de portería

| Aspecto | Detalle |
|---------|---------|
| Quién | Usuario SmartCSET con permiso de portería (ej. usuario `porteria`) |
| Autenticación | Login con usuario/contraseña → sesión PHP (misma que la web) |
| Puede | Identificar por rostro, enrolar (según procedimiento), captura manual, pistola, registrar ingreso/salida |
| No configura | `base_url` ni `verify_tls` (archivo `app_config.json` — solo TI) |
| Debe | Usar **Salir** al terminar; confirmar foto/datos en identificación facial |
| No debe | Compartir credenciales; enrolar sin autorización institucional |

Si el login funciona pero catálogos o registro fallan con 403, el usuario **no tiene** el menú de portería asignado en el servidor — lo resuelve TI/admin en la web, no desde el desktop.

---

## Administrador (servidor / web)

| Aspecto | Detalle |
|---------|---------|
| Quién | Usuario con privilegios administrativos en SmartCSET |
| Relación con desktop | El `.exe` **no** expone un panel de administración completo al operario |
| Código presente no expuesto | Existen páginas en código (`inicio`, `salida`, `entradas`) **sin** menú visible en el shell actual |
| CRUD de entradas | Requiere rol admin en el **servidor**; no hay entrada de menú desktop en as-built para el operario |
| Auditoría / sesiones | Forzar cierre de sesiones y monitoreo vía **módulos web** (p. ej. SIEM), no desde esta app |

Esta referencia **no** lista IDs de menú web: consultar documentación y BD del monorepo / admin web.

---

## TI / instalador

| Aspecto | Detalle |
|---------|---------|
| Quién | Personal de soporte o infraestructura del centro |
| Responsabilidades | Instalar `.exe`, editar `app_config.json`, backup de config, actualizar binario, red/cámara, escalar a desarrollo |
| Producción | `verify_tls: true` con certificado válido |
| Laboratorio | Puede usar `verify_tls: false` solo con cert autofirmado |
| No hace | Operar la fila de portería salvo capacitación o soporte puntual |

Runbooks: [`../operacion/instalacion.md`](../operacion/instalacion.md), [`../operacion/despliegue-produccion.md`](../operacion/despliegue-produccion.md).

---

## Resumen

| Rol | Usa la app día a día | Configura cliente | Gestiona permisos en BD/web |
|-----|----------------------|-------------------|-----------------------------|
| Operario | Sí | No | No |
| Admin | Opcional / soporte | No (salvo TI) | Sí (servidor) |
| TI | Instalación y soporte | Sí | Según su perfil en el sistema |

---

## Documentos relacionados

- Tutorial: [`tutorial-primer-uso.md`](tutorial-primer-uso.md)
- Explicación UI: [`explicacion.md`](explicacion.md)
- Incidentes: [`../operacion/incidentes-seguridad.md`](../operacion/incidentes-seguridad.md)
