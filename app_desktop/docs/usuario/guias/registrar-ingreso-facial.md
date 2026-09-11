# Guía: registrar ingreso/salida por rostro

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 6

**Audiencia:** Operario de portería  
**Tipo:** Guía práctica Diátaxis

---

## Cuándo usar esta guía

La persona **ya tiene rostro enrolado** y la cámara funciona. Es el método recomendado en portería.

Si no reconoce el rostro → use [`registrar-ingreso-manual.md`](registrar-ingreso-manual.md).  
Si nunca se ha enrolado → use [`enrolar-rostro.md`](enrolar-rostro.md).

---

## Pasos

1. Pida a la persona que mire a la cámara (panel izquierdo). Buena luz frontal ayuda.
2. Cuando vea el rostro en el video, presione **Identificar**.
3. Si hay coincidencia, aparece el **panel de confirmación** con:
   - Foto de cuando se enroló (no la captura en vivo, salvo fallback)
   - Documento, nombre, tipo, entrada, programa (si aplica)
4. Compare foto y datos con la persona frente a usted.
5. Presione **Registrar**, o espere unos segundos (registro automático si no cancela).
6. El sistema registra **ingreso** o **salida** según si ya tenía ingreso abierto hoy.

---

## Resultados esperados

| Mensaje / resultado | Significado |
|---------------------|-------------|
| "Ingreso registrado" | Entró al centro |
| "Salida registrada" | Salió del centro |
| No reconoce el rostro | Usar captura manual o enrolar |
| Persona incorrecta en confirmación | Presione **Cancelar** — no se registra nada |

---

## Cancelar

Si la persona identificada **no es** quien está delante, **Cancelar** en el panel de confirmación. No se escribe nada en la base de datos.

---

## Si algo falla

| Problema | Acción |
|----------|--------|
| "No se detectó rostro" | Mejorar iluminación; acercar a la cámara; o usar manual |
| Identifica a otra persona | Cancelar; avisar a TI si se repite |
| Cámara negra | Cerrar otras apps de cámara; reiniciar; fallback manual |

---

## Documentos relacionados

- Tutorial primer uso: [`../tutorial-primer-uso.md`](../tutorial-primer-uso.md)
- Enrolar: [`enrolar-rostro.md`](enrolar-rostro.md)
- Manual: [`registrar-ingreso-manual.md`](registrar-ingreso-manual.md)
