# AGENTS.md — Instructor routers

Routers JSON bajo `backend/routers/instructor/v1/`. Auth: `require_instructor.php` (sesión + instructor o admin lectura).

| Método | Ruta | Escritura |
|--------|------|-----------|
| GET | `fichas/listar.php` | No |
| GET | `asistencia/listar.php?id_ficha=&fecha=` | No |
| GET | `asistencia/exportar.php?id_ficha=&fecha=` | No |
| GET | `dashboard/resumen.php?fecha=` | No |
| POST | `asistencia/registrar.php` | Solo instructor |
| PUT | `asistencia/actualizar.php` | Solo instructor |

Servicio: `backend/services/instructor/asistencia_service.php`.
