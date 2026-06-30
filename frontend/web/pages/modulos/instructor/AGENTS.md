# AGENTS.md — Módulo instructor (Mis Fichas)

Vista: `fichas/index.php`. Mutaciones y filtros AJAX vía `SmartcsetInstructorRouter` → `/routers/instructor/v1/`.

- Presentación HTML: `lib/instructor_ui.php` (badges, etiquetas).
- Lógica de datos: `backend/services/instructor/asistencia_service.php`.
- Admin: solo lectura sobre cualquier ficha en ejecución.
