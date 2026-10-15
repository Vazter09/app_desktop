# ADR-05 — URL del servidor preconfigurada

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 5 (configuración controlada), 7 (operación estable en portería), 8 (TLS / destino de confianza)

**Estado:** Aceptada (as-built)

---

## Contexto

El operario de portería no es administrador de red. Pedir la URL del backend en cada login induce errores tipográficos, apuntar a hosts incorrectos y soporte innecesario. El PC de portería es un puesto fijo hacia un servidor institucional conocido.

---

## Decisión

La **`base_url`** (y opcionalmente `verify_tls`) vive en configuración de instalación, **no** en un diálogo de primer uso:

| Entorno | Origen típico | Ejemplo |
|---------|---------------|---------|
| Desarrollo | `runtime/app_config.json` | `https://localhost/smartcset` |
| Empaquetado portería | seed `packaging/app_config.porteria.json` embebido / copiado a runtime | `https://10.5.213.111/smartcset` (lab) o host institucional |

Carga: [`../src/config.py`](../../src/config.py). El login solo pide **usuario y contraseña** SmartCSET.

Cambio de servidor = cambio de archivo de config por TI (ver manual de instalación), no por el operario.

---

## Consecuencias

**Positivas**

- UX alineada al rol portería; menos errores de URL.
- Destino HTTPS fijo facilita inventariar el canal (MSPI Eje 5/8).
- Seeds distintos por ambiente (lab vs producción) sin tocar código.

**Negativas / trade-offs**

- Mover el puesto a otro centro/servidor requiere intervención de TI.
- Seed de laboratorio puede traer `verify_tls: false` (cert autofirmado); en producción institucional debe ser `true` con certificado válido — riesgo residual documentado en seguridad MSPI.
- Si la URL está mal, todos los síntomas se ven como “no conecta” / “respuesta inválida”; el diagnóstico empieza por `base_url`.
