# Estándares Internacionales Citados en la Documentación MSPI
## Guía de Estudio Completa

**Documento generado:** Junio 2026
**Fuente:** Análisis de 9 documentos MSPI (MinTIC) + referencias internacionales

---

## Tabla Rápida de Contenidos
1. [Estándares ISO/IEC principales](#estándares-isoiec-principales)
2. [Marco NIST (USA)](#marco-nist-usa)
3. [OWASP (Open Web Application Security Project)](#owasp-open-web-application-security-project)
4. [MITRE (Militar-Tecnológico USA)](#mitre-militar-tecnológico-usa)
5. [OCDE (Organización para la Cooperación y Desarrollo Económico)](#ocde-organización-para-la-cooperación-y-desarrollo-económico)
6. [UNESCO (Organización de las Naciones Unidas)](#unesco-organización-de-las-naciones-unidas)
7. [UNICEF (Fondo de las Naciones Unidas para la Infancia)](#unicef-fondo-de-las-naciones-unidas-para-la-infancia)
8. [Reglamento Europeo de IA (AI Act)](#reglamento-europeo-de-ia-ai-act)
9. [Matriz de referencia: cuál aplica a SmartCSET](#matriz-de-referencia-cuál-aplica-a-smartcset)

---

## Estándares ISO/IEC principales

### 1. ISO/IEC 27001:2022 — Sistema de Gestión de Seguridad de la Información (SGSI)

**¿Qué es?**
Estándar internacional que especifica los requisitos para establecer, implementar, mantener y mejorar continuamente un sistema de gestión de seguridad de la información (SGSI) en una organización.

**Alcance:**
- Define cómo proteger información sensible
- Establece políticas, procedimientos, controles y responsabilidades
- Requiere auditoría interna y revisión del management

**Relevancia para SmartCSET:**
- **CRÍTICA** — el MSPI colombiano está completamente basado en ISO 27001
- Todas las bases de datos personales (tab_personas, tab_log_ingresos, tab_usuarios) deben estar bajo este estándar
- Requiere:
  - Inventario de activos de información
  - Evaluación de riesgos (qué puede salir mal y cuánta probabilidad hay)
  - Implementación de controles (cifrado, control de acceso, copias de seguridad)
  - Auditoría periódica (mínimo anual)
  - Plan de respuesta a incidentes

**Dónde se menciona:**
- Documentos 01-07 (marco general MSPI)
- Documento 09 (seguridad IA) — citado como base para fiabilidad y seguridad de sistemas IA

**Costo de certificación (referencia global):**
Certificar un sistema bajo ISO 27001 típicamente cuesta entre $5.000 - $20.000 USD en auditoría externa + tiempo interno de implementación.

---

### 2. ISO/IEC 9000:2015 — Sistemas de Gestión de Calidad — Conceptos Fundamentales

**¿Qué es?**
Proporciona los conceptos y el vocabulario fundamental para la gestión de la calidad, incluyendo qué significa "calidad" y "validez" de un proceso o producto.

**Alcance:**
- Define términos como "eficacia", "eficiencia", "conformidad"
- Establece el principio de "mejora continua"
- Aplica a cualquier tipo de organización (privada, pública, pequeña, grande)

**Relevancia para SmartCSET:**
- **MEDIA** — citada en el MSPI para definir qué significa que el sistema sea "válido" o "confiable"
- Aplica a SmartCSET en el sentido de que cualquier output del sistema (reportes, registros, decisiones) debe cumplir con criterios de calidad documentados
- Requiere:
  - Definición clara de qué es "correcto" para SmartCSET
  - Documentación de procesos y estándares de calidad
  - Medición de conformidad

**Dónde se menciona:**
- Documento 09 (criterios de fiabilidad de sistemas IA) — secc. 11.4.1 "Válido y fiable"

---

### 3. ISO/IEC TS 5723:2022 — Información y tecnología de la información — Seguridad de información — Características de sistemas de inteligencia artificial confiables

**¿Qué es?**
Especificación técnica (TS) que define las características que debe tener un sistema de IA para ser considerado "fiable" desde el punto de vista de seguridad: válido, seguro, resiliente, responsable y transparente.

**Alcance:**
- Válido y fiable (el sistema funciona correctamente bajo condiciones esperadas)
- Seguro (protege confidencialidad, integridad y disponibilidad)
- Seguridad y resiliencia (se recupera ante fallos o ataques)
- Responsable y transparente (se puede auditar y explicar)
- Explainable e interpretable (se entiende por qué tomó una decisión)
- Privacidad mejorada (protege datos personales)
- Justo (sin sesgo o discriminación)

**Relevancia para SmartCSET:**
- **CRÍTICA SI se incorpora IA** — no aplica al módulo actual, pero DEBE aplicarse si se agregan componentes de IA al nuevo módulo "registro y seguimiento de personal"
- Define los 7 atributos de "fiabilidad" que exige el documento 09
- Si se usa reconocimiento facial, OCR inteligente o scoring automático, este estándar es OBLIGATORIO

**Dónde se menciona:**
- Documento 09 (sección 11.4 "Riesgos y fiabilidad de la IA") — es la base normativa de la tabla de características de sistemas IA confiables

---

### 4. ISO/IEC 22989:2022 — Información y tecnología de la información — Conceptos y terminología para inteligencia artificial

**¿Qué es?**
Vocabulario y definiciones oficiales para términos de IA, reconocidos internacionalmente. Define qué es un "modelo", un "dataset", un "algoritmo", "hallucination", "bias", etc.

**Alcance:**
- Estandariza el lenguaje para evitar ambigüedades
- Más de 50 términos IA definidos oficialmente
- Base para la comunicación técnica en IA a nivel global

**Relevancia para SmartCSET:**
- **MEDIA** — aplicable si se introduce IA, para documentación y comunicación técnica clara con MinTIC, COLCERT y auditores
- Garantiza que cuando digas "el modelo tiene sesgo", todos entienden exactamente qué significa
- Necesaria para auditorías y reportes de conformidad

**Dónde se menciona:**
- Documento 09 (glosario de términos IA en secciones iniciales) — aproximadamente 30+ términos definidos siguiendo ISO 22989

---

### 5. ISO/IEC 42001:2023 — Información y tecnología de la información — Sistema de gestión para inteligencia artificial

**¿Qué es?**
Estándar de gestión específico para sistemas de IA, análogo a ISO 27001 pero enfocado en los riesgos únicos de IA: sesgo, alucinaciones, ataques adversariales, envenenamiento de datos, etc.

**Alcance:**
- Establecer gobernanza de sistemas IA
- Identificar y mitigar riesgos específicos de IA
- Implementar controles técnicos y humanos
- Auditar y monitorear continuamente

**Relevancia para SmartCSET:**
- **CRÍTICA SI se incorpora IA** — si el nuevo módulo "registro y seguimiento de personal" usa cualquier componente IA, deberá certificarse bajo ISO 42001
- Define procesos obligatorios:
  - Evaluación de impacto en privacidad y seguridad (POPIA/DPIA para IA)
  - Pruebas de robustez y adversariales
  - Supervisión humana (human-in-the-loop)
  - Auditoría anual mínimo
  - Plan de respuesta a incidentes IA

**Dónde se menciona:**
- Documento 09 (recomendaciones de arquitectura segura, sección 12.2) — es la base para el ciclo de vida de sistemas IA mencionado

---

### 6. ISO/IEC 27701:2019 — Extensión de ISO 27001 para Privacidad de Datos

**¿Qué es?**
Complemento de ISO 27001 que agrega controles específicos para protección de datos personales según GDPR (Reglamento General de Protección de Datos europeo), aunque es aplicable a cualquier jurisdicción que tenga leyes de privacidad.

**Alcance:**
- Consentimiento informado (ARCO: Acceso, Rectificación, Cancelación, Oposición)
- Derechos del titular de datos
- Gestión del ciclo de vida de datos personales
- Relación entre responsables y encargados de tratamiento

**Relevancia para SmartCSET:**
- **CRÍTICA** — SmartCSET procesa datos personales (cédulas, fotos, datos biográficos, posiblemente datos de menores)
- Colombia adoptó la Ley 1581/2012 (Protección de Datos Personales), que está alineada con GDPR y este estándar
- Requiere:
  - Política de tratamiento documentada y publicada
  - Registro de actividades de tratamiento (quién accede, cuándo, por qué)
  - Cifrado de datos en tránsito y en reposo
  - Derecho al olvido (posibilidad de eliminar datos en ciertos casos)
  - Evaluación de impacto en privacidad (PIA) antes de nuevas funcionalidades

**Dónde se menciona:**
- Documentos 01-07 (marco MSPI menciona GDPR como referencia internacional)
- Documento 09 (sección sobre privacidad mejorada)

---

## Marco NIST (USA)

NIST es la Institución Nacional de Estándares y Tecnología de Estados Unidos. Sus marcos se consideran la referencia global de facto para ciberseguridad e IA.

### 1. NIST AI RMF 1.0 — Artificial Intelligence Risk Management Framework

**¿Qué es?**
Marco de gestión de riesgos para sistemas de IA, publicado en 2023. Define un ciclo de vida de 4 fases para identificar, medir, manejar y comunicar riesgos de IA.

**Las 4 fases del RMF:**
1. **MAP** — Mapear: definir el contexto del sistema IA (qué hace, a quién afecta)
2. **MEASURE** — Medir: evaluar riesgos usando métricas (sesgo, robustez, privacidad)
3. **MANAGE** — Manejar: implementar controles para mitigar riesgos
4. **GOVERN** — Gobernar: supervisar, auditar y mejorar continuamente

**Relevancia para SmartCSET:**
- **CRÍTICA SI se incorpora IA** — es la metodología recomendada por MinTIC en el documento 09 para gestionar riesgos de sistemas IA
- Proporciona estructura clara para evaluar cada riesgo (ej: "¿qué tan probable es que el sistema presente sesgo en la clasificación de aprendices?")
- Integrable con ISO 42001

**Dónde se menciona:**
- Documento 09 (sección 11 "Recomendaciones para identificación y gestión de riesgos IA") — el ciclo de vida y el núcleo de gestión de riesgos descrito está basado en NIST AI RMF

---

### 2. NIST AI 600-1 — Artificial Intelligence Risk Management Framework: Generative AI Profile

**¿Qué es?**
Perfil específico del NIST AI RMF para Inteligencia Artificial Generativa (IA Generativa): LLMs (Large Language Models), modelos de difusión de imágenes, etc.

**Riesgos únicos de GenAI:**
- **Inyección de Prompts** — un usuario malicioso modifica el prompt del sistema para hacerlo generar contenido dañino
- **Alucinaciones** — el modelo genera información falsa con confianza
- **Extracción de prompts** — extraer el prompt del sistema para replicar el comportamiento
- **Envenenamiento de datos** — modificar los datos de entrenamiento para sesguar el modelo
- **Jailbreak** — eludir los guardarraíles del sistema para hacer que genere contenido prohibido

**Relevancia para SmartCSET:**
- **MEDIA — NO APLICA HOY** — solo si se decide incorporar un chatbot/LLM interno para soporte (ej. "asistente de consultas para aprendices")
- Si se usa Gemini, Claude, ChatGPT u otro LLM público, este estándar exige:
  - No pasar datos personales al LLM (CRÍTICO)
  - Validar respuestas antes de mostrarlas a usuarios
  - Monitorear intentos de jailbreak/inyección de prompts
  - Documentar las capacidades y limitaciones del LLM

**Dónde se menciona:**
- Documento 09 (sección 12.1 "Top 10 OWASP 2025 para LLMs y GenAI") — los 10 riesgos listados provienen de este perfil de NIST

---

### 3. NIST AI 100-2e2025 — Adversarial Machine Learning: A Taxonomy and Terminology of Attacks and Mitigations

**¿Qué es?**
Taxonomía oficial de NIST para ataques adversariales contra sistemas de ML/IA y las defensas correspondientes.

**Tipos de ataques adversariales:**
- **Ataque evasión** — perturbar datos de entrada para que el modelo falle (ej: agregar ruido a una foto para que no se reconozca un rostro)
- **Ataque envenenamiento** — contaminar los datos de entrenamiento para sesgar el modelo
- **Ataque extracción** — extraer información del modelo (qué datos se usaron para entrenar)
- **Ataque transferencia** — crear un ataque que funciona contra múltiples modelos
- **Ataque interpretabilidad** — descubrir cómo el modelo toma decisiones para explotarlo

**Relevancia para SmartCSET:**
- **MEDIA — SI se incorpora IA** — especialmente si se usa reconocimiento facial/biométrico
- Un atacante podría intentar presentar una foto manipulada para hacer que el sistema no reconozca a una persona
- Requiere pruebas de robustez (adversarial testing) durante el desarrollo

**Dónde se menciona:**
- Documento 09 (sección 12.1.2.2 "Pruebas de Seguridad Proactivas") — menciona "pruebas adversariales" y "fuzzing"

---

## OWASP (Open Web Application Security Project)

OWASP es una comunidad global de seguridad que publica las vulnerabilidades más críticas en aplicaciones web.

### 1. OWASP Top 10 — 2021 (Clásico para aplicaciones web)

**¿Qué es?**
Lista de las 10 vulnerabilidades más críticas encontradas en aplicaciones web:

1. **A01:2021 — Broken Access Control** — falta de control de acceso (ej: un usuario puede acceder a datos de otro usuario)
2. **A02:2021 — Cryptographic Failures** — fallos en cifrado (datos sensibles sin cifrar)
3. **A03:2021 — Injection** — inyección SQL, command injection, LDAP injection
4. **A04:2021 — Insecure Design** — falta de controles de seguridad desde el diseño
5. **A05:2021 — Security Misconfiguration** — configuración insegura de servidores, frameworks
6. **A06:2021 — Vulnerable and Outdated Components** — usar librerías con vulnerabilidades conocidas
7. **A07:2021 — Authentication & Session Management Failures** — gestión pobre de sesiones y autenticación
8. **A08:2021 — Software and Data Integrity Failures** — no validar integridad de software/datos
9. **A09:2021 — Logging & Monitoring Failures** — falta de logs de seguridad y auditoría
10. **A10:2021 — Server-Side Request Forgery (SSRF)** — hacer que el servidor acceda a recursos no autorizados

**Relevancia para SmartCSET:**
- **CRÍTICA** — toda aplicación web debe validarse contra estos 10 riesgos
- SmartCSET ya está protegido contra A03 (Injection) gracias a los prepared statements y funciones PL/pgSQL
- **Áreas de riesgo actuales en SmartCSET:**
  - A01 (control de acceso) — la tabla `tab_menu_usuarios` implementa RBAC, está bien
  - A02 (cifrado) — necesario cifrar campos sensibles en reposo
  - A07 (autenticación) — revisar implementación del login en `index.php`
  - A09 (logging) — auditoría con `usr_insert/fec_insert` existe, pero falta logging de intentos fallidos de login

**Dónde se menciona:**
- Documentos 01-07 (marco general MSPI menciona OWASP como referencia)
- No aparece explícitamente en documento 09, pero es implícito para cualquier sistema web

---

### 2. OWASP Top 10 — 2025 para LLMs y Aplicaciones de IA Generativa

**¿Qué es?**
Lista actualizada específicamente para sistemas que usan IA Generativa / LLMs (ChatGPT, Gemini, Claude, etc.):

1. **LLM01:2025 — Inyección de Prompts** — un usuario modifica el prompt para cambiar el comportamiento del LLM
2. **LLM02:2025 — Divulgación de Información Sensible** — el LLM revela datos de entrenamiento o información privada
3. **LLM03:2025 — Cadena de Suministro Insegura** — usar modelos o plugins con vulnerabilidades
4. **LLM04:2025 — Envenenamiento de Datos y Modelo** — datos de entrenamiento contaminados o modelo comprometido
5. **LLM05:2025 — Manejo Inadecuado de la Salida** — no validar/sanitizar las respuestas del LLM antes de mostrarlas
6. **LLM06:2025 — Agencia Excesiva** — el LLM tiene permisos para ejecutar acciones sin supervisión humana
7. **LLM07:2025 — Filtración de Prompts de Sistema** — el usuario extrae el "prompt del sistema" (las instrucciones internas)
8. **LLM08:2025 — Debilidades de Vector y Representaciones Vectoriales** — vulnerabilidades en bases de datos vectoriales (RAG)
9. **LLM09:2025 — Desinformación** — el LLM genera información falsa presentada como verdadera
10. **LLM10:2025 — Consumo Ilimitado** — falta de límites en uso de API/recursos (un atacante agota los recursos)

**Relevancia para SmartCSET:**
- **MEDIA — NO APLICA HOY** — solo si se decide usar LLM/ChatBot interno
- **CRÍTICA si se integra un LLM público** (ej: usar Gemini de Google para procesar consultas de aprendices)
- Requiere:
  - Nunca pasar datos personales al LLM
  - Validar respuestas antes de mostrarlas
  - Implementar rate limiting (máximo N solicitudes por usuario/día)
  - Monitorear intentos de inyección de prompts

**Dónde se menciona:**
- Documento 09 (sección 12.1 "Evaluación de Riesgos Especializada") — tabla con "Top 10 OWASP 2025 de riesgos y mitigaciones para LLMs y aplicaciones de IA Generativa"

---

## MITRE (Militar-Tecnológico USA)

MITRE es una institución sin fines de lucro que trabaja en tecnología y seguridad para defensa y gobierno.

### 1. MITRE ATLAS — Adversarial Threat Landscape for Artificial Intelligence Systems

**¿Qué es?**
Base de conocimiento global (similar a OWASP Top 10 o MITRE ATT&CK para ciberseguridad) que documenta técnicas de ataque contra sistemas de IA, observadas en el mundo real.

**Estructura:**
- **Tácticas** — objetivos de alto nivel (ej: "obtener acceso a un modelo")
- **Técnicas** — métodos específicos para lograr ese objetivo
- **Procedimientos** — ejemplos reales de ataques observados

**Ejemplos de ataques documentados:**
- Inyección de prompts contra ChatGPT (técnica: "jailbreak")
- Envenenamiento de datos en datasets públicos de GitHub
- Ataque de evasión contra sistemas de reconocimiento facial usando anteojos adversariales
- Extracción de modelos copiando el comportamiento del API

**Relevancia para SmartCSET:**
- **MEDIA — SI se incorpora IA** — referencia útil para diseño de pruebas de seguridad y auditoría
- Ayuda a priorizar qué ataques son más probables en el contexto del SENA (ej: un aprendiz malicioso intentando colar fotos falsas en el sistema)

**Dónde se menciona:**
- Documento 09 (bibliografía, referencias internacionales)

---

## OCDE (Organización para la Cooperación y Desarrollo Económico)

La OCDE es un organismo internacional de 38 países desarrollados que publica recomendaciones sobre políticas públicas, incluyendo seguridad digital e IA.

### 1. OCDE Recommendation on Artificial Intelligence — 2019

**¿Qué es?**
Primera recomendación oficial de la OCDE sobre IA, publicada en mayo 2019. Define 5 principios rectores:

1. **AI should benefit people and the planet** — la IA debe beneficiar a la humanidad, no causarle daño
2. **AI systems should be human-centered and explainable** — los sistemas deben ser transparentes y explicables
3. **AI should be robust, secure and safe** — resiliencia ante fallos y ataques
4. **AI systems should be accountable** — responsabilidad clara sobre quién es responsable si algo sale mal
5. **There should be appropriate human involvement in significant decisions** — supervisión humana en decisiones críticas

**Relevancia para SmartCSET:**
- **MEDIA** — principios generales de gobernanza IA aplicables si se incorpora IA
- Alineados con el MSPI documento 09 (los 6 "principios rectores para implementación de IA segura" están basados en OCDE + UNESCO)
- Establece que la IA en entidades públicas debe ser **accountable** — alguien en el SENA responde si el sistema tiene un comportamiento discriminatorio

**Dónde se menciona:**
- Documentos 01-07 y 09 (marco normativo internacional)

---

### 2. OCDE — Facts not Fakes: Tackling Disinformation, Strengthening Information Integrity — 2024

**¿Qué es?**
Guía de la OCDE sobre cómo combatir desinformación, especialmente relevante en contexto de IA generativa que puede producir contenido falso convincente.

**Relevancia para SmartCSET:**
- **BAJA — HOY** — aplicable si se integra un LLM que podría generar información falsa (ej: respuestas a consultas de aprendices)
- Establece que debería haber validación humana de cualquier información generada por IA antes de mostrarla a usuarios

**Dónde se menciona:**
- Documento 09 (riesgos de desinformación en LLM01:2025)

---

## UNESCO (Organización de las Naciones Unidas para la Educación, Ciencia y Cultura)

### 1. UNESCO Recommendation on the Ethics of Artificial Intelligence — 2021

**¿Qué es?**
Recomendación de UNESCO que define principios éticos para sistemas de IA a nivel mundial, enfocado en derechos humanos y justicia social.

**Los 4 pilares:**
1. **Respeto de la autonomía humana** — IA no debe eliminar la capacidad de tomar decisiones humanas
2. **Promoción del bienestar humano y equidad** — IA no debe generar discriminación
3. **Transparencia y explicabilidad** — se debe poder auditar y explicar decisiones IA
4. **Accountability y responsabilidad** — alguien debe responder si la IA causa daño

**Relevancia para SmartCSET:**
- **MEDIA — SI se incorpora IA** — especialmente importante dado que el SENA es una entidad educativa que atiende a menores de edad potencialmente
- Establece obligación de explicabilidad: si se usa IA para decidir sobre aprendices (ej: scoring de riesgo), se debe poder explicar por qué
- Prohíbe usar IA para discriminar por raza, género, edad, etc.

**Dónde se menciona:**
- Documento 09 (sección 10 "Principios rectores para implementación de IA segura") — los principios rectores están fuertemente basados en UNESCO

---

### 2. UNESCO — Estudio Preliminar sobre un Posible Instrumento Normativo Relativo a la Ética de la IA — 2019

**¿Qué es?**
Documento previo a la recomendación 2021, que analiza el estado del arte en ética de IA a nivel mundial.

**Relevancia para SmartCSET:**
- **BAJA** — principalmente histórico/referencial
- Útil para entender cómo UNESCO llegó a sus principios finales

**Dónde se menciona:**
- Documento 09 (referencias bibliográficas)

---

## UNICEF (Fondo de las Naciones Unidas para la Infancia)

### 1. UNICEF — Policy Guidance on AI for Children — 2021 (Version 2.0)

**¿Qué es?**
Guía específica de UNICEF sobre cómo proteger a niños, niñas y adolescentes (NNA) en sistemas de IA.

**Principios clave:**
- Priorizar el interés superior del niño
- Proteger la privacidad de datos de NNA
- No usar perfiles/scoring sobre NNA sin supervisión humana
- Transparencia y explicabilidad en sistemas que afecten a niños
- Participación de niños en decisiones sobre IA que los afecte

**Relevancia para SmartCSET:**
- **CRÍTICA** — los aprendices SENA frecuentemente son menores de edad
- Si el sistema procesa datos de aprendices menores, DEBE cumplir con esta guía
- Específicamente: no se puede usar IA para perfilar, clasificar o tomar decisiones automáticas sobre menores sin intervención humana
- Requiere:
  - Obtener consentimiento de padres/tutores para menores
  - Cifrado especial y controles de acceso reforzados para datos de NNA
  - Auditoría anual específica en datos de menores
  - Plan de protección de datos de NNA documentado

**Dónde se menciona:**
- Documento 09 (sección 12.4.1.2 "Desarrollo" — menciona que "en el caso de que el sistema interactúe con grupos vulnerables (ej: menores de edad), deberán aplicarse controles adicionales en materia de protección de datos... tal como se establece en la Circular SIC")

**Conexión importante:** La "Circular SIC" mencionada en el MSPI documento 09 es la implementación colombiana de los principios UNICEF.

---

## Reglamento Europeo de IA (AI Act)

### 1. Reglamento (UE) 2024/1689 — Ley de Inteligencia Artificial (AI Act) — Aprobado en 2024, entra en vigencia gradualmente 2025-2026

**¿Qué es?**
Primer marco regulatorio integral de una región/país para gobernar sistemas de IA. Define niveles de riesgo y obligaciones correspondientes.

**Los 4 niveles de riesgo:**
1. **Riesgo mínimo** — sin obligaciones especiales (ej: recomendadores de películas)
2. **Riesgo limitado** — obligaciones de transparencia (ej: chatbots deben decir "soy un chatbot", no fingir ser humano)
3. **Riesgo alto** — afecta salud, seguridad o derechos fundamentales (ej: herramientas de selección de personal, sistemas biométricos)
   - Requisitos: validación técnica exhaustiva, testing adversarial, supervisión humana significativa, documentación completa, auditoría periódica
4. **Riesgo inaceptable** — prohibido (ej: reconocimiento biométrico en tiempo real en espacios públicos para vigilancia masiva)

**Tabla de clasificación de riesgo (ejemplos del AI Act):**

| Sistema IA | Ejemplo | Clasificación |
|---|---|---|
| Recomendador de películas | Netflix | Mínimo |
| Chatbot de soporte | Zendesk con IA | Limitado |
| Sistema de selección de personal | ATS (Applicant Tracking System) | Alto |
| Reconocimiento biométrico fronterizo | Control en aeropuertos | Alto |
| Reconocimiento facial masivo en calles | Cámaras CCTV con IA | Inaceptable |
| Scoring de crédito automático | Banco otorga crédito basado en IA | Alto |
| Detección de fraude en banca | Sistema IA que bloquea transacciones | Alto |

**Relevancia para SmartCSET:**
- **MEDIA — HOY**; **CRÍTICA si se incorpora IA**
- Es la referencia que MinTIC cita en el documento 09 como "marco internacional de facto"
- Si se usa IA para decisiones sobre aprendices (scoring, clasificación, selección), probablemente sea "Riesgo Alto" según el AI Act, lo que requiere:
  - **Testing adversarial** — intentar "engañar" el modelo
  - **Supervisión humana significativa** — un humano revisa y aprueba decisiones críticas
  - **Explicabilidad** — poder explicar por qué el sistema clasificó a un aprendiz de cierta forma
  - **Auditoría anual mínimo** — validar que no presenta sesgo discriminatorio
  - **Documentación exhaustiva** — registro de decisiones, cambios de modelo, incidentes

**Implementación en Colombia:**
Colombia aún no ha adoptado un "AI Act" propio, pero el MSPI documento 09 cita el AI Act europeo como referencia internacional y adoptará un marco similar (esperado en Decreto 2026-2027).

**Dónde se menciona:**
- Documento 09 (sección 12.1.2 "Fortalecimiento de Guardarraíles") — menciona el "Nuevo Reglamento Europeo de Inteligencia Artificial, aprobado en 2024" y sus 4 niveles de riesgo
- Documento 09 (sección 12.1.2.1 "Monitoreo y Detección Automatizada") — tabla comparativa de regulación de IA: EE.UU., UE/AI Act, América Latina

---

## Matriz de Referencia: Cuál Aplica a SmartCSET

**Leyenda:** ✅ = Crítica (aplicar ahora) | 🟡 = Media (revisar si módulo IA) | ⚠️ = Baja (solo referencial)

### Aplicabilidad Actual (SmartCSET 2026 sin IA)

| Estándar / Marco | Estado actual | Acción |
|---|---|---|
| **ISO/IEC 27001:2022** | ✅ CRÍTICA | Inventariar assets de información, clasificar por Confidencialidad/Integridad/Disponibilidad, documentar políticas de seguridad, implementar plan de respuesta a incidentes |
| **ISO/IEC 9000:2015** | 🟡 MEDIA | Documentar qué significa "calidad" de datos/reportes de SmartCSET (ej: "un registro de ingreso válido incluye: documento, hora, puerta"); validar conformidad periódicamente |
| **ISO/IEC 27701:2019** | ✅ CRÍTICA | Documentar política de tratamiento de datos personales (por Decreto 1377/2013 colombiano); implementar derechos ARCO; cifrar datos en tránsito/reposo |
| **NIST AI RMF 1.0** | ⚠️ BAJA (HOY) | No aplica; revisar si se decide agregar IA |
| **OWASP Top 10 2021** | ✅ CRÍTICA | Auditoría de seguridad web: validar control de acceso (RBAC), cifrado, prepared statements, logging de autenticación, etc. |
| **OWASP Top 10 2025 (LLM)** | ⚠️ BAJA (HOY) | No aplica; revisar si se integra chatbot/LLM |
| **OCDE Recommendation on AI 2019** | ⚠️ BAJA (HOY) | No aplica; revisar si se decide agregar IA |
| **UNESCO Recommendation on AI Ethics 2021** | ⚠️ BAJA (HOY) | No aplica; revisar si se decide agregar IA |
| **UNICEF Policy Guidance on AI for Children** | 🟡 MEDIA | Aunque no hay IA, SmartCSET procesa datos de aprendices menores → implementar controles reforzados de protección de datos NNA (Circular SIC) |
| **EU AI Act 2024** | 🟡 MEDIA | Marco de referencia para diseño futuro de módulos IA; si se incorpora IA, clasificar según riesgo (mínimo/limitado/alto/inaceptable) |
| **MITRE ATLAS** | ⚠️ BAJA (HOY) | Referencia para testing adversarial si se incorpora IA |
| **NIST AI 600-1 (GenAI)** | ⚠️ BAJA (HOY) | No aplica; revisar si se integra LLM/chatbot |
| **NIST AI 100-2e2025 (Adversarial ML)** | ⚠️ BAJA (HOY) | Referencia para testing adversarial si se incorpora IA de reconocimiento/clasificación |

### Aplicabilidad Futura (Si se incorpora IA al nuevo módulo "Registro y Seguimiento de Personal")

| Estándar / Marco | Nivel requerido | Qué haría |
|---|---|---|
| **ISO/IEC 42001:2023** | ✅ CRÍTICA | Certificación obligatoria; auditoría anual mínimo; evaluación de impacto en privacidad (PIA) antes de desplegar |
| **ISO/IEC TS 5723:2022** | ✅ CRÍTICA | Validar que el sistema IA cumple con 7 atributos: válido, seguro, resiliente, responsable, transparente, privacidad mejorada, justo (sin sesgo) |
| **NIST AI RMF 1.0** | ✅ CRÍTICA | Implementar ciclo MAP-MEASURE-MANAGE-GOVERN para gestión de riesgos IA |
| **NIST AI 600-1 (GenAI)** | 🟡 MEDIA | Solo si se usa LLM (chatbot, procesamiento de lenguaje natural) |
| **NIST AI 100-2e2025 (Adversarial ML)** | 🟡 MEDIA | Si se usa ML/clasificación automática → pruebas adversariales obligatorias |
| **OWASP Top 10 2025 (LLM)** | 🟡 MEDIA | Solo si se integra LLM/chatbot |
| **UNESCO Recommendation on AI Ethics** | ✅ CRÍTICA | Asegurar cumplimiento de 4 pilares: autonomía humana, bienestar/equidad, transparencia, accountability |
| **UNICEF Policy Guidance on Children** | ✅ CRÍTICA | Controles reforzados para datos de aprendices menores; NO automatizar decisiones sobre menores sin supervisión humana |
| **EU AI Act 2024** | 🟡 MEDIA | Clasificar según riesgo; si es "Riesgo alto" → testing, supervisión humana, auditoría; si es "Inaceptable" → prohibido |
| **MITRE ATLAS** | 🟡 MEDIA | Considerar técnicas de ataque documentadas contra tipo de IA seleccionado |

---

## Plan de Estudio Recomendado

### Fase 1: Fundamentos (2-4 semanas)
1. **Leer ISO/IEC 27001 Resumen ejecutivo** (~4h) — entender estructura de SGSI
2. **Leer NIST AI RMF ciclos** (~2h) — estructura MAP-MEASURE-MANAGE-GOVERN
3. **Revisar OWASP Top 10 2021** (~3h) — vulnerabilidades web comunes
4. **Leer documento 01-07 del MSPI** (~6h) — marco nacional

### Fase 2: Profundización en IA (si se decide incorporar)
5. **ISO/IEC 42001:2023 — Resumen** (~3h)
6. **ISO/IEC TS 5723:2022 — los 7 atributos de fiabilidad** (~2h)
7. **OWASP Top 10 2025 para LLM** (~3h) — si se usa chatbot
8. **EU AI Act — clasificación de riesgo** (~2h)
9. **UNICEF Guidance on Children** (~2h) — crítico para aprendices menores

### Fase 3: Implementación Técnica
10. **Documento MSPI 09 completo** (~8h) — guía técnica y recomendaciones
11. **Auditoría SmartCSET actual contra OWASP Top 10** (~4h)
12. **Documento 08_02 (ICC)** (~2h) — determinar si SENA debe registrarse ante COLCERT

---

## Resumen: Las 5 Normas ABSOLUTAMENTE CRÍTICAS para SmartCSET

1. **ISO/IEC 27001** — SGSI base
2. **ISO/IEC 27701** — Privacidad de datos personales
3. **OWASP Top 10 2021** — Vulnerabilidades web
4. **Ley 1581/2012 + Decreto 1377/2013** — Colombia (protección de datos)
5. **MSPI MinTIC** — Marco nacional obligatorio

Si se incorpora IA, agregar:
6. **ISO/IEC 42001** — Gestión de IA
7. **UNICEF Guidance on Children** — Protección de menores
8. **EU AI Act** — Clasificación de riesgo (referencia internacional)

---

**Nota:** Todos estos documentos están disponibles en línea. Los que son de libre acceso (OWASP, NIST, UNESCO, UNICEF) pueden descargarse directamente. Los ISO requieren compra (~$200 USD c/u) pero universidades y entidades públicas suelen tener acceso institucional.

*Documento preparado como guía de estudio para cumplimiento regulatorio de SmartCSET — Junio 2026*
