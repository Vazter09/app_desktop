# Guía: registrar ingreso/salida manual (documento)

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 6

**Audiencia:** Operario de portería  
**Tipo:** Guía práctica Diátaxis

---

## Cuándo usar esta guía

- El rostro no es reconocido.
- La persona no está enrolada y no va a enrolarse ahora.
- La cámara no funciona.
- Prefiere verificar por documento.

Es el **fallback** que mantiene la portería operativa (disponibilidad).

---

## Pasos

1. En el **formulario central**, seleccione el **tipo de documento** (CC, TI, CE, etc.).
2. Escriba el **número de documento**.
3. Presione **Consultar** para buscar a la persona en el sistema.
4. Si aparece:
   - Verifique nombres y tipo de persona.
   - Presione **Registrar ingreso** o **Registrar salida** según el caso mostrado / flujo de la pantalla.
5. Si es persona nueva:
   - Complete los campos requeridos (nombres, tipo de persona, entrada).
   - Registre según las opciones disponibles en el formulario.

> El sistema también puede decidir ingreso vs salida según reglas del servidor (ingreso abierto del día). Si un registro se rechaza por duplicado, la persona ya tiene ingreso abierto hoy.

---

## Con pistola

Si usa pistola de códigos, el formulario se puede llenar solo. Ver [`lectura-pistola.md`](lectura-pistola.md) y luego verifique y registre como arriba.

---

## Si algo falla

| Problema | Acción |
|----------|--------|
| Persona no encontrada | Verificar tipo/número; registrar como visitante si el procedimiento del centro lo permite |
| Catálogos vacíos / 403 | Avisar a TI (permiso de menú portería) |
| "No se pudo conectar" | Avisar a TI |
| Ingreso duplicado rechazado | Normal: ya hay ingreso abierto — probablemente corresponde salida |

---

## Documentos relacionados

- Facial: [`registrar-ingreso-facial.md`](registrar-ingreso-facial.md)
- Pistola: [`lectura-pistola.md`](lectura-pistola.md)
- Tutorial: [`../tutorial-primer-uso.md`](../tutorial-primer-uso.md)
