# ADR-04 — SFace con vector de 128 dimensiones

**Módulo:** `app_desktop`  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3 (integridad del dato biométrico), 6 (dato sensible — tamaño y formato fijos), 8 (evitar mismatch silencioso 512≠128)

**Estado:** Aceptada (as-built)

---

## Contexto

El diseño temprano (Bug 19) asumió embeddings de **512 floats** sin haber fijado el modelo. Al integrar **SFace** (`face_recognition_sface_2021dec.onnx` del zoo OpenCV) resultó que el modelo entrega **128 dimensiones**. Mantener 512 habría forzado otro modelo o padding incorrecto.

La migración `alter_tab_enrolamiento_facial_vector_128.sql` y el schema activo (`tab_personas.val_patron_facial VECTOR(128)`, `tab_log_ingresos.facial_embedding VECTOR(128)`) alinean BD y cliente **antes** de datos reales de producción.

---

## Decisión

- Modelo de reconocimiento: **SFace** (128-d); detección: **YuNet**.
- Contrato cliente↔servidor: arrays JSON de **exactamente 128** floats.
- Validación servidor: `BIOMETRIA_VECTOR_DIMENSION = 128` en `backend/services/porteria/biometria_service.php`.
- Umbral de distancia coseno por defecto en servidor: configurable; cliente puede enviar `umbral_distancia`.

**AS-BUILT:** la referencia por persona se persiste en `tab_personas.val_patron_facial` (VECTOR **128**), no en un vector de 512.

---

## Consecuencias

**Positivas**

- Coherencia extremo a extremo: motor → HTTP → PHP → pgvector.
- Tests con vectores sintéticos de 128 dims (`app_desktop/tests/`).
- Menor tamaño de payload y de índice frente a 512-d.

**Negativas / trade-offs**

- Documentación o ramas antiguas que digan “512” están **obsoletas**; no reintroducir esa cifra.
- Cambio de modelo futuro (otra dimensión) exige migración de columna + redeploy de funciones + cliente + tests — no es un flip de config.
- Enrolamientos hechos con dimensión incorrecta no hacen match; el síntoma típico es “siempre falla identificación”.
