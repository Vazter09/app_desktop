# Tutorial: primer uso — Operario de portería

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 6

**Audiencia:** Operario de portería (primer día)  
**Tipo:** Tutorial Diátaxis

---

## Qué logrará al terminar

Al completar este tutorial sabrá: abrir la app, iniciar sesión, reconocer la pantalla principal, registrar un ingreso (rostro o documento) y cerrar sesión correctamente.

Tiempo estimado: 15–20 minutos con acompañamiento de TI.

---

## 1. ¿Qué es esta aplicación?

SmartCSET Portería registra **ingresos y salidas** en el centro de formación. Puede identificar personas por **rostro**, por **documento** o con **pistola de códigos** (QR / barras).

Se conecta al mismo SmartCSET de la web: los registros quedan en la misma base de datos del servidor.

---

## 2. Abrir la aplicación

1. Haga doble clic en el icono **SmartCSET Portería**.
2. Espere la pantalla de inicio de sesión (ventana maximizada).
3. La primera vez puede tardar unos segundos más.

---

## 3. Iniciar sesión

1. En **Usuario**, escriba su usuario SmartCSET (a menudo viene prellenado `porteria`).
2. En **Contraseña**, escriba su clave.
3. Presione **Ingresar al sistema**.

| Resultado | Qué hacer |
|-----------|-----------|
| Login correcto | Pasa a la pantalla de reconocimiento |
| "Contraseña incorrecta" | Revise mayúsculas e intente de nuevo |
| "No se pudo conectar" | Avise a TI (red o servidor) |

> No cierre la aplicación con la X del sistema si puede evitarlo: use **Salir** al terminar el turno.

---

## 4. Conocer la pantalla principal

Tras el login verá **tres zonas**:

```
┌─────────────────────────────────────────────────────────┐
│  SMARTCSET          [su usuario]            [Salir]     │
├─────────────┬───────────────────────┬───────────────────┤
│   CÁMARA    │    FORMULARIO         │    HUELLA         │
│   (video)   │    (documento, etc.)  │    (ilustrativa)  │
└─────────────┴───────────────────────┴───────────────────┘
```

- **Izquierda:** cámara en vivo.  
- **Centro:** documento, nombres, botones Consultar / Registrar / Enrolar / Identificar.  
- **Derecha:** imagen ilustrativa de huella — **no** hay lector conectado en esta versión.

La barra superior muestra su usuario y el botón **Salir**.

---

## 5. Primer registro (elige un camino)

### Opción A — Por rostro (si la persona ya está enrolada)

1. Pida que mire a la cámara.
2. Presione **Identificar**.
3. Revise foto y datos en el **panel de confirmación**.
4. Presione **Registrar** o espere el registro automático (pocos segundos).
5. El sistema decide solo si es **ingreso** o **salida**.

Detalle: [`guias/registrar-ingreso-facial.md`](guias/registrar-ingreso-facial.md).

### Opción B — Por documento (siempre disponible)

1. Elija tipo de documento y escriba el número.
2. Presione **Consultar**.
3. Verifique datos y registre ingreso o salida.

Detalle: [`guias/registrar-ingreso-manual.md`](guias/registrar-ingreso-manual.md).

### Primera vez de una persona (enrolar rostro)

Si debe registrar el rostro por primera vez: [`guias/enrolar-rostro.md`](guias/enrolar-rostro.md).

### Pistola de códigos

Si hay pistola USB: [`guias/lectura-pistola.md`](guias/lectura-pistola.md).

---

## 6. Ingreso o salida — no elige usted

| Situación | Acción del sistema |
|-----------|-------------------|
| No tiene ingreso abierto hoy | Registra **ingreso** |
| Ya está dentro (ingreso abierto) | Registra **salida** |

---

## 7. Cerrar sesión al final del turno

1. Presione **Salir** arriba a la derecha.
2. La app cierra sesión en el servidor y se cierra.

Si se cuelga o apagan el PC de golpe, avise a TI para revisar sesiones abiertas.

---

## 8. Buenas prácticas del primer día

1. **Siempre confirme** foto y datos antes de aceptar un registro biométrico.
2. **No comparta** usuario ni contraseña.
3. Si la cara falla, use documento — **no bloquee** la fila.
4. Enrolar solo con autorización institucional del centro.
5. Ante "No se pudo conectar", avise a TI de inmediato.

---

## 9. Preguntas frecuentes (resumen)

| Pregunta | Respuesta corta |
|----------|-----------------|
| ¿Cámara negra? | Cierre Teams/Zoom; reinicie app; si sigue, use manual y avise TI |
| ¿Sin cédula física? | Puede digitar el número si lo conoce |
| ¿Guarda la contraseña en el PC? | No; solo sesión mientras la app está abierta |
| ¿Sin red? | No funciona; necesita intranet al servidor |
| ¿Persona equivocada? | Cancelar en confirmación; si ya registró, contacte administrador |

---

## Siguientes lecturas

- Guías prácticas en [`guias/`](guias/)
- Roles: [`referencia-roles.md`](referencia-roles.md)
- Porqués técnicos (lectura opcional): [`explicacion.md`](explicacion.md)
