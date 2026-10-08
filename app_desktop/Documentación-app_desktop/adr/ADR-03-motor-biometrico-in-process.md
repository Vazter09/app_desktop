# ADR-03 — Motor biométrico in-process

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 5 (arquitectura de componentes), 7 (disponibilidad / menos puntos de fallo), 8 (sin servicio HTTP local expuesto)

**Estado:** Aceptada (as-built) — diverge del diseño original en `REGLAS_APP_ESCRITORIO_SGI.md` §5

---

## Contexto

El diseño inicial proponía **dos procesos**: UI Tkinter + motor biométrico como servicio HTTPS en loopback (TLS local, vector 512-d). Eso aislaba OpenCV del hilo de UI y obligaba TLS también en app↔motor (E1-A02 extendido).

En la implementación, la cámara ya carga OpenCV en el mismo proceso; un segundo proceso duplicaría modelos ONNX, puertos, certificados locales y fallos de arranque.

---

## Decisión

Ejecutar el motor facial (**YuNet + SFace**) **in-process** dentro del mismo intérprete Python que la UI:

- Código: [`../src/motor/`](../../src/motor/) (`FaceEmbedder`, modelos ONNX embebidos).
- Orquestación: [`../src/ui/facial_modal.py`](../../src/ui/facial_modal.py) / panel de reconocimiento.
- No hay `http.server` local ni puerto loopback para biometría.

Si el motor falla, la app mantiene **fallback manual** (formulario / pistola) — Pilar 4 Estabilidad.

---

## Consecuencias

**Positivas**

- Un solo proceso a desplegar y monitorear; empaquetado PyInstaller más simple.
- Sin superficie de red local (nada escuchando en 127.0.0.1 para embeddings).
- Reutiliza la misma instancia OpenCV de la cámara.

**Negativas / trade-offs**

- Un crash nativo de OpenCV puede tumbar toda la app (mitigado por hooks de excepción y fallback manual).
- No aplica el control “TLS loopback app↔motor” del diseño original (documentado como no implementado en [`../09-seguridad-mspi.md`](../09-seguridad-mspi.md)).
- Inferencia y UI compiten por el mismo proceso; hay que cuidar hilos/colas para no congelar Tkinter.
