# Guía: enrolar un rostro

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 6

**Audiencia:** Operario de portería  
**Tipo:** Guía práctica Diátaxis

---

## Cuándo usar esta guía

Una persona debe **enrolarse** (registrar su rostro) **antes** de poder usarse **Identificar** con cámara.

> **Importante:** Solo enrolar a personas que hayan autorizado el tratamiento de datos biométricos según la política del centro. La app, en el estado actual, **no** muestra un modal de consentimiento propio — la autorización es responsabilidad del procedimiento institucional.

---

## Pasos

1. En el formulario central, ingrese el **documento** de la persona (y tipo de documento).
2. Consulte / asegúrese de que los datos de la persona son correctos en el sistema.
3. Pida que mire a la cámara con buena iluminación.
4. Presione **Enrolar** (o **Capturar Rostro** si ya tenía enrolamiento y se está actualizando).
5. Espere el mensaje de confirmación del sistema.
6. A partir de ese momento puede usar **Identificar** para ingresos/salidas.

La foto de enrolamiento se guarda en el **servidor** (no como archivo permanente en el PC de portería). Esa foto es la que verá después en el panel de confirmación.

---

## Después del enrolamiento

Pruebe de inmediato:

1. **Identificar** con la misma persona.
2. Revisar foto y datos en confirmación.
3. Registrar o cancelar según corresponda.

Guía de uso diario: [`registrar-ingreso-facial.md`](registrar-ingreso-facial.md).

---

## Si algo falla

| Problema | Acción |
|----------|--------|
| "No se detectó rostro" | Mejorar luz; distancia; reintentar |
| Foto / enrolamiento rechazado | Formato inválido o error de servidor — avisar a TI |
| Persona no existe en sistema | Primero registrar datos por captura manual |
| Error de conexión | Avisar a TI |

---

## Documentos relacionados

- Facial diario: [`registrar-ingreso-facial.md`](registrar-ingreso-facial.md)
- Manual: [`registrar-ingreso-manual.md`](registrar-ingreso-manual.md)
- Explicación (foto servidor): [`../explicacion.md`](../explicacion.md)
