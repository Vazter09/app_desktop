# Guía: lectura con pistola de códigos

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 5, 6

**Audiencia:** Operario de portería  
**Tipo:** Guía práctica Diátaxis

---

## Cuándo usar esta guía

Hay una **pistola USB** (o lector) configurada como teclado (HID) que lee QR o código de barras / PDF417 de documentos.

La app interpreta la ráfaga de caracteres y **rellena el formulario** central. Usted sigue siendo quien consulta y registra.

---

## Pasos

1. Coloque el cursor / enfoque en el área del formulario de ingreso (como cuando digita un documento).
2. Escanee el documento o código QR con la pistola.
3. Espere a que el formulario se complete (tipo y número de documento, y campos que el parseo pueda obtener).
4. **Verifique** visualmente que los datos coinciden con el documento físico.
5. Presione **Consultar** si no se disparó la búsqueda automáticamente.
6. Confirme identidad y registre ingreso o salida.

Si el código no se entiende, digite el documento a mano ([`registrar-ingreso-manual.md`](registrar-ingreso-manual.md)).

---

## Buenas prácticas

- No escanee “a ciegas” sin mirar el formulario.
- Si el parseo deja campos raros o incompletos, corrija a mano antes de registrar.
- La pistola no sustituye la confirmación facial: si luego usa rostro, siga revisando el panel de confirmación.

---

## Si algo falla

| Problema | Acción |
|----------|--------|
| No aparece nada al escanear | Verificar que Windows reconoce la pistola; probar en Bloc de notas |
| Datos incompletos o incorrectos | Corregir manualmente; avisar a TI si es recurrente con el mismo tipo de código |
| Duplica caracteres / corta | Ajustar sufijo Enter de la pistola con TI |

---

## Documentos relacionados

- Manual: [`registrar-ingreso-manual.md`](registrar-ingreso-manual.md)
- Tutorial: [`../tutorial-primer-uso.md`](../tutorial-primer-uso.md)
