# 11 — Riesgos y deuda técnica

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 5, 7, 8

---

## 11.1 Riesgos activos

| ID | Riesgo | Impacto | Probabilidad | Mitigación actual | Residual |
|----|--------|---------|--------------|-------------------|----------|
| R1 | Falso positivo facial → ingreso erróneo | Alto | Media | Umbral coseno servidor + confirmación visual + auto-cancelable | Calibrar con rostros reales SENA |
| R2 | `verify_tls: false` en producción | Alto | Media | Documentado; override debe ser explícito | Error humano al copiar seed lab |
| R3 | Robo / acceso físico al PC portería | Alto | Baja | Sesión con timeout servidor; vector no en disco | Webcam y UI accesibles físicamente |
| R4 | Fuga de fotos JPG en filesystem servidor | Alto | Media | Permisos directorio; sin E2 | Sin cifrado en reposo |
| R5 | Suplantación / coerción en enrolamiento | Alto | Media | Operario presente | Sin consentimiento UI Ley 1581 |
| R6 | Backend o red caída | Alto | Media | Mensaje de error; no hay offline | Portería bloqueada sin servidor |
| R7 | Sesión colgada tras crash duro | Medio | Baja | Logout en close/atexit | Kill -9 sin atexit |
| R8 | Build `.exe` roto sin detección | Medio | Media | Build manual + checklist | Sin test de empaquetado en CI |
| R9 | Confusión por páginas huérfanas en código | Bajo | Alta | Documentar as-built | Deuda de navegación |
| R10 | Placeholder huella tomado por feature real | Medio | Media | Documentar RF-15 | Endpoints de prueba existen |

## 11.2 Deuda técnica (inventario)

| Deuda | Área | Prioridad | Notas |
|-------|------|-----------|-------|
| CI/CD ausente | E10 / calidad | Media | Suite 34 no corre en cada commit |
| Consentimiento biométrico UI | Fase 0 / Ley 1581 | Alta | Hueco crítico pre-producción con personas reales |
| Cifrado E2 fotos/vectores | E2 | Institucional | Diferido al SENA (2026-07-09) |
| Motor 2 procesos HTTPS | E1-A02 / Fase 2 | Baja | Diseño original no as-built |
| SDK huella real | RF-15 | Media | Templates sintéticos |
| Cache local de fotos | Ops | Baja | Mencionado en HANDOFF; código actual no escribe cache |
| Tests UI Tkinter | E10 | Media | Solo pruebas manuales M1–M8 |
| Semver / LICENSE módulo | Gobernanza | Baja / institucional | —
| Inicio / Salida / Entradas huérfanas | UX | Media | Código presente; sin menú |
| Rate limit específico identificación facial | E3 | Baja | Solo login IP heredado |
| Countdown visual de sesión | E4 | Baja | Timeout solo servidor |

## 11.3 Riesgos de congruencia (documentación vs código)

| Riesgo | Cómo evitarlo |
|--------|---------------|
| Asumir árbol `app/` | Fuente de verdad = `src/` |
| Asumir motor HTTPS separado | As-built = in-process |
| Asumir sidebar / dashboard | Post-login solo ingreso |
| Asumir huella productiva | Placeholder |
| Asumir E2 cumplido | Explícitamente diferido |

## 11.4 Plan de contención sugerido (no compromiso de sprint)

1. **Antes de prod con personas reales:** consentimiento UI + `verify_tls: true` + matriz Fase 0 biométrica.
2. **Corto plazo ingeniería:** CI que ejecute `unittest discover` contra lab.
3. **Medio plazo:** decidir si se eliminan o se exponen páginas huérfanas.
4. **Fase 2 seguridad:** evaluar motor facial en proceso aislado HTTPS loopback.

## 11.5 Indicadores de alerta operativa

- Login SSL fallando tras cambio de cert → revisar `verify_tls` y CA.
- `usr_insert = postgres` en ingresos → sesión/`app.usuario` rota en servidor.
- Match facial degradado → umbral, iluminación, calidad webcam.
- Sesiones activas huérfanas en SIEM → fallos de logout en clientes.

Fuentes: [`../09-seguridad-mspi.md`](../09-seguridad-mspi.md), [`../11-matriz-trazabilidad.md`](../11-matriz-trazabilidad.md), [`../08-plan-y-evidencia-pruebas.md`](../08-plan-y-evidencia-pruebas.md).
