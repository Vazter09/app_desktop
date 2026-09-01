# 06 — Manual de usuario

**Módulo:** App de Escritorio SGI — SmartCSET  
**Versión documental:** 1.0.0  
**Fecha:** 2026-09-01  
**Audiencia:** Operario de portería

---

## 1. ¿Qué es esta aplicación?

SmartCSET Portería es la aplicación de escritorio para **registrar ingresos y salidas** de personas en el centro de formación. Permite identificar personas por **rostro**, por **documento** o con **pistola de códigos** (QR / barras).

La aplicación se conecta al mismo sistema SmartCSET que usa la web — los registros quedan en la misma base de datos.

---

## 2. Iniciar la aplicación

1. Haga doble clic en el icono **SmartCSET Portería** (o ejecute el acceso directo).
2. Espere a que aparezca la pantalla de inicio de sesión.
3. La ventana se abrirá maximizada.

> **Nota:** La primera vez puede tardar unos segundos más mientras se prepara el entorno.

---

## 3. Iniciar sesión

1. En el campo **Usuario**, ingrese su usuario de SmartCSET (por defecto viene prellenado `porteria`).
2. En el campo **Contraseña**, ingrese su clave.
3. Presione **Ingresar al sistema**.

| Resultado | Qué hacer |
|-----------|-----------|
| Login correcto | Pasa automáticamente a la pantalla de reconocimiento |
| "Contraseña incorrecta" | Verifique mayúsculas y vuelva a intentar |
| "No se pudo conectar" | Avise a TI — puede ser problema de red o servidor |

> **Importante:** No cierre la aplicación sin usar el botón **Salir** en la esquina superior derecha.

---

## 4. Pantalla principal — Reconocimiento multibiométrico

Tras iniciar sesión verá una pantalla con **tres zonas**:

```
┌─────────────────────────────────────────────────────────┐
│  SMARTCSET          [su usuario]            [Salir]     │
├─────────────┬───────────────────────┬───────────────────┤
│             │                       │                   │
│   CÁMARA    │    FORMULARIO         │    HUELLA         │
│   (video    │    (documento,        │    (imagen        │
│    en vivo) │     nombres, etc.)    │     ilustrativa)  │
│             │                       │                   │
└─────────────┴───────────────────────┴───────────────────┘
```

### Barra superior

- Muestra su nombre de usuario.
- Botón **Salir**: cierra sesión y la aplicación.

---

## 5. Registrar ingreso o salida por rostro (recomendado)

### 5.1 Persona ya enrolada (tiene rostro registrado)

1. Pida a la persona que mire a la cámara (panel izquierdo).
2. Cuando vea su rostro en el video, presione **Identificar**.
3. Si el sistema la reconoce, aparecerá un **panel de confirmación** con:
   - Foto de la persona (de cuando se enroló)
   - Datos: documento, nombre, tipo, entrada, programa
4. Revise que la foto y los datos coincidan con la persona frente a usted.
5. Presione **Registrar** o espere unos segundos (registro automático).
6. El sistema registra **ingreso** o **salida** automáticamente según corresponda.

| Mensaje / resultado | Significado |
|---------------------|-------------|
| "Ingreso registrado" | La persona entró al centro |
| "Salida registrada" | La persona salió del centro |
| No reconoce el rostro | Use captura manual (sección 6) o enrolamiento (sección 7) |

### 5.2 Cancelar un registro

Si la persona identificada **no es** quien está frente a la cámara, presione **Cancelar** en el panel de confirmación. No se registrará nada.

---

## 6. Registrar por documento (captura manual)

Use este método cuando:
- El rostro no es reconocido
- La persona no está enrolada
- La cámara no funciona

### Pasos

1. En el **formulario central**, seleccione el **tipo de documento** (CC, TI, CE, etc.).
2. Escriba el **número de documento**.
3. Presione **Consultar** para buscar a la persona en el sistema.
4. Si aparece, verifique los datos y presione **Registrar ingreso** o **Registrar salida**.
5. Si es persona nueva, complete los campos requeridos (nombres, tipo de persona, entrada) y registre.

### Con pistola de códigos

1. Escanee el documento o código QR con la pistola.
2. El formulario se llena automáticamente.
3. Verifique los datos y registre.

---

## 7. Enrolar un rostro (primera vez)

Una persona debe **enrolarse** (registrar su rostro) antes de poder ser identificada por cámara.

### Pasos

1. En el formulario central, ingrese el **documento** de la persona.
2. Pida que mire a la cámara.
3. Presione **Enrolar** (o **Capturar Rostro** si ya tenía enrolamiento previo).
4. Espere el mensaje de confirmación.
5. A partir de ese momento, la persona puede identificarse con **Identificar**.

> **Importante:** Solo enrolar a personas que hayan autorizado el tratamiento de sus datos biométricos según la política del centro.

---

## 8. ¿Ingreso o salida?

**No necesita elegir** — el sistema decide automáticamente:

| Situación de la persona | Acción del sistema |
|-------------------------|-------------------|
| No tiene ingreso abierto hoy | Registra **ingreso** |
| Ya tiene ingreso abierto (está dentro) | Registra **salida** |

---

## 9. Área de huella dactilar

La zona derecha muestra una **imagen ilustrativa** de huella dactilar. En la versión actual, el lector de huellas **no está conectado** — es solo visual. Use rostro o documento.

---

## 10. Cerrar sesión

1. Presione **Salir** en la barra superior.
2. La aplicación cierra sesión en el servidor y se cierra.

**No cierre la ventana con la X sin que la app responda** — si se cuelga, avise a TI para verificar que no quedó sesión abierta.

---

## 11. Preguntas frecuentes

### ¿Qué hago si la cámara no muestra imagen?

1. Verifique que la webcam esté conectada.
2. Cierre otras aplicaciones que usen la cámara (Teams, Zoom).
3. Reinicie la aplicación.
4. Si persiste, use captura manual y avise a TI.

### ¿Qué hago si dice "No se pudo conectar"?

El servidor SmartCSET no responde. Avise a TI — puede ser mantenimiento de red o del servidor.

### ¿Puedo registrar a alguien sin cédula física?

Sí, si conoce el número de documento, puede ingresarlo manualmente en el formulario.

### ¿Se guarda mi contraseña en el PC?

No. Solo se guarda la sesión mientras la aplicación está abierta. Al cerrar, la sesión termina.

### ¿Puedo usar la app sin internet?

No. Necesita conexión a la red del centro (intranet) donde está el servidor SmartCSET.

### ¿Qué pasa si identifico a la persona equivocada?

Siempre revise la **foto y los datos** en el panel de confirmación antes de registrar. Si ya registró por error, contacte al administrador del sistema.

---

## 12. Buenas prácticas de portería

1. **Siempre confirme** foto y datos antes de registrar un ingreso biométrico.
2. **No comparta** su usuario y contraseña con otros operarios.
3. **Cierre sesión** al terminar su turno (botón Salir).
4. Si la identificación facial falla, **no bloquee** la fila — use documento manual.
5. **Enrolar** solo a personas con autorización institucional.

---

## Documentos relacionados

- Instalación (TI): [`05-manual-instalacion.md`](05-manual-instalacion.md)
- Soporte técnico: [`10-operacion-y-mantenimiento.md`](10-operacion-y-mantenimiento.md)
