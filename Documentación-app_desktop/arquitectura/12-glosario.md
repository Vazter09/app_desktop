# 12 — Glosario

**Módulo:** app_desktop  
**Responsable:** Equipo de Desarrollo  
**Última revisión:** 2026-09-03  
**Ejes MSPI:** 3, 6, 7

---

## 12.1 Términos de negocio

| Término | Definición |
|---------|------------|
| **SGI** | Sistema de Gestión de Ingresos (módulo de portería SmartCSET). |
| **Portería** | Puesto operativo de control de acceso del centro de formación. |
| **Operario** | Usuario principal de la app de escritorio. |
| **Ingreso abierto** | Fila en `tab_log_ingresos` con `fec_salida = fec_ingreso` (persona aún dentro). |
| **Enrolamiento** | Alta del vector facial de referencia (y foto) de una persona. |
| **Identificación** | Comparación de un embedding vivo contra enrolamientos almacenados. |
| **Novedad** | Flujo servidor cuando la persona no existe o requiere registro especial. |
| **metodo_aut** | Método de autenticación del evento: 1 manual, 2 QR, 3 barras, 4 facial, 5 huella. |

## 12.2 Términos técnicos de la app

| Término | Definición |
|---------|------------|
| **As-built** | Arquitectura realmente implementada (no aspiracional). |
| **arc42-lite** | Subconjunto práctico de secciones arc42 usado en `docs/arquitectura/`. |
| **src/** | Árbol de código fuente vigente del cliente desktop. |
| **SmartcsetClient** | Cliente HTTP stdlib con cookie jar y TLS configurable. |
| **AppShell** | Contenedor post-login (topbar + contenido); sin sidebar. |
| **FacialRecognitionPanel** | Núcleo UI de cámara, facial, enrolar y registro. |
| **FaceEmbedder** | Motor YuNet + SFace que produce embedding 128-d. |
| **Embedding / vector facial** | Lista de 128 floats que representa un rostro. |
| **In-process** | Motor biométrico en el mismo proceso Python que la UI. |
| **Frozen** | Ejecución empaquetada PyInstaller (`is_frozen()`). |
| **onefile** | Empaque de un solo `.exe` con deps embebidas. |
| **app_config.json** | Config local: `base_url`, `verify_tls`. |
| **writable_root** | Directorio escribible (config/logs): `runtime/` o carpeta del `.exe`. |
| **resource_root** | Recursos de solo lectura: `src/` o `_MEIPASS`. |
| **Página huérfana** | Código de página presente sin navegación/exposición UI. |
| **Placeholder huella** | UI + templates sintéticos sin SDK de lector. |

## 12.3 Términos de plataforma / seguridad

| Término | Definición |
|---------|------------|
| **PHPSESSID** | Cookie de sesión PHP compartida con la web. |
| **pgvector / HNSW** | Extensión y índice para búsqueda por similitud de embeddings. |
| **YuNet** | Detector de rostros ONNX (opencv_zoo). |
| **SFace** | Modelo de reconocimiento facial ONNX; salida 128-d. |
| **MSPI** | Modelo de Seguridad y Privacidad de la Información (MinTIC). |
| **E1…E11** | Entregables de blindaje técnico Fase 1 SmartCSET. |
| **E2** | Cifrado en reposo (pendiente/diferido para fotos biométricas). |
| **E6** | Validación de uploads (MIME real de fotos). |
| **E8** | Hardening de red / TLS. |
| **verify_tls** | Flag local que activa/desactiva verificación del certificado HTTPS. |
| **ADR** | Architecture Decision Record. |
| **RF / RNF** | Requisito funcional / no funcional. |

## 12.4 Acrónimos rápidos

| Sigla | Expansión |
|-------|-----------|
| SENA | Servicio Nacional de Aprendizaje |
| HTTPS | Hypertext Transfer Protocol Secure |
| ONNX | Open Neural Network Exchange |
| TLS | Transport Layer Security |
| UI | User Interface |
| BD | Base de datos |
| CI | Continuous Integration |
| MIME | Multipurpose Internet Mail Extensions |

## 12.5 Relación con otros glosarios

Definiciones de dominio SmartCSET más amplias: [`../01-vision-y-alcance.md`](../01-vision-y-alcance.md) §9. Este glosario prioriza términos necesarios para leer las secciones arc42 de `app_desktop`.
