# TEAcompáñame — Especificación Técnica y Funcional (v2.0 Refinada)

> **Propósito**: Asistente virtual empático para padres/cuidadores de niños con Trastorno del Espectro Autista (TEA), con capacidad de detectar patrones conductuales y generar una bitácora estructurada automática.

---

## Índice

1. [Visión General](#1-visión-general)
2. [Arquitectura del Sistema](#2-arquitectura-del-sistema)
3. [Perfiles de Usuario y Roles](#3-perfiles-de-usuario-y-roles)
4. [Flujo de Interacción (UX)](#4-flujo-de-interacción-ux)
5. [Prompt del Sistema (Instrucciones Base)](#5-prompt-del-sistema-instrucciones-base)
6. [Modelo de Datos](#6-modelo-de-datos)
7. [Sistema de Registro Conductual](#7-sistema-de-registro-conductual)
8. [Seguridad y Privacidad](#8-seguridad-y-privacidad)
9. [Estrategia de Memoria a Largo Plazo](#9-estrategia-de-memoria-a-largo-plazo)
10. [Stack Tecnológico Recomendado](#10-stack-tecnológico-recomendado)
11. [Métricas de Éxito](#11-métricas-de-éxito)
12. [Roadmap de Implementación](#12-roadmap-de-implementación)
13. [Casos de Borde y Manejo de Errores](#13-casos-de-borde-y-manejo-de-errores)
14. [Apéndice A: Esquemas JSON Completos](#14-apéndice-a-esquemas-json-completos)
15. [Apéndice B: Glosario de Términos](#15-apéndice-b-glosario-de-términos)

### Novedades en v2.1
- **2.3** Estrategia de internacionalización (i18n) con mapeo de categorías
- **7.3.1** Patrón regex concreto para el parser `<conducta>`
- **7.4.2** Deduplicación en el cliente (app), no en el LLM
- **8.6** Resolución de conflictos de sincronización (last-write-wins)
- **8.7** Recursos de emergencia por país
- **9.4** Estrategia de asignación de tokens (token budget)
- **10.2** Requisitos de accesibilidad WCAG

---

## 1. Visión General

### 1.1 Problema que Resuelve

Las familias con niños TEA enfrentan una sobrecarga de información y estrés. Los profesionales (terapeutas, neuropediatras) necesitan datos objetivos sobre la evolución del niño, pero los padres no tienen herramientas para registrar patrones de forma sistemática. Las conversaciones cotidianas contienen información conductual valiosa que se pierde al no registrarse.

### 1.2 Solución Propuesta

TEAcompáñame es un asistente con IA integrado en una app móvil que:
- Ofrece apoyo emocional y orientación a padres en lenguaje natural
- Detecta automáticamente eventos conductuales relevantes en las conversaciones
- Genera registros estructurados JSON que alimentan una bitácora persistente
- Correlaciona patrones a lo largo del tiempo usando memoria prolongada (1M tokens)
- Facilita la comunicación familia-profesionales mediante informes exportables

### 1.3 Principios de Diseño

| Principio | Descripción |
|-----------|-------------|
| **Empatía primero** | Toda interacción valida la experiencia del cuidador |
| **No juicio** | Nunca se cuestionan las decisiones o emociones de los padres |
| **No reemplaza** | No sustituye al profesional sanitario; lo complementa |
| **Invisible pero poderoso** | El registro conductual ocurre en segundo plano sin fricción |
| **Privacidad por defecto** | Todos los datos pertenecen al usuario, no al sistema |
| **Adaptativo** | El lenguaje y la profundidad se ajustan al perfil del cuidador |

---

## 2. Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────┐
│                   App Móvil (Flutter/RN)             │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │ Chat UI     │  │ Panel de     │  │ Exportar/   │  │
│  │ (TEAcom-    │  │ Bitácora     │  │ Compartir  │  │
│  │ páñame)     │  │ Conductual   │  │ Informes   │  │
│  └──────┬──────┘  └──────┬───────┘  └─────┬──────┘  │
│         │                │                │          │
│  ┌──────▼────────────────▼────────────────▼──────┐  │
│  │          Capa de Servicios Local               │  │
│  │  ┌─────────────┐  ┌───────────────────────┐   │  │
│  │  │ Gestor de   │  │ Parser de Conducta    │   │  │
│  │  │ Memoria     │  │ (extrae JSON del      │   │  │
│  │  │ Local (1M   │  │  prompt, limpia,      │   │  │
│  │  │ tokens)     │  │  valida el esquema)   │   │  │
│  │  └─────────────┘  └──────────┬────────────┘   │  │
│  │  ┌─────────────┐  ┌──────────▼────────────┐   │  │
│  │  │ SQLite Local│  │ Cliente LLM (on-device│   │  │
│  │  │ (bitácora,  │  │ o API remota)         │   │  │
│  │  │ perfiles)   │  │                        │   │  │
│  │  └─────────────┘  └────────────────────────┘   │  │
│  └─────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│             Backend Cloud (Opcional)                  │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │ Auth        │  │ Sincronización│  │ Analytics  │  │
│  │ (OAuth2)    │  │ entre        │  │ anónimos   │  │
│  │             │  │ dispositivos  │  │ (opt-in)   │  │
│  └─────────────┘  └──────────────┘  └────────────┘  │
└──────────────────────────────────────────────────────┘
```

### 2.1 Modos de Operación

| Modo | LLM | Conexión | Privacidad | Uso |
|------|-----|----------|------------|-----|
| **Local** | On-device (CPU/GPU móvil) | Sin internet | Máxima | Modo por defecto |
| **Híbrido** | API remota + caché local | Requiere internet | Alta (datos cifrados) | Consultas complejas |
| **Solo nube** | API remota potente | Requiere internet | Media | Análisis avanzados, resúmenes |

### 2.2 Estrategia de Inferencia On-Device

Para el modo local, se recomiendan modelos optimizados para móvil:
- **Phi-3-mini / Gemma-2B / Llama-3.2-1B** cuantizados a 4 bits
- **Context window de 1M tokens** mediante interpolación posicional (YaRN o NTK-aware scaling)
- **Inferencia** mediante ML Kit, MediaPipe, o ejecutores ONNX Runtime Mobile
- **Latencia objetivo**: < 2s por respuesta en dispositivos gama media

---

## 3. Perfiles de Usuario y Roles

### 2.3 Estrategia de Internacionalización (i18n)

El JSON de conducta utiliza **field names en español** (fecha, tipo, descripcion, etc.) como lengua franca del sistema, independientemente del idioma de la interfaz de usuario. Esta decisión se toma porque:
- Los field names son un contrato técnico interno (entre el LLM y la app)
- Simplifica el parser y la validación (un solo esquema para todos los idiomas)
- El contenido de los campos (descripcion, notas, etc.) se genera en el idioma del usuario

**Mapeo de categorías por idioma**:

| Categoría (ES) | Label EN | Label PT |
|----------------|----------|----------|
| crisis | meltdown / crisis | crise |
| estereotipia | stereotypy | estereotipia |
| rechazo_alimentario | food refusal | recusa alimentar |
| problema_sueño | sleep issue | problema de sono |
| logro_comunicativo | communication milestone | marco comunicativo |
| logro_social | social milestone | marco social |
| desencadenante_sensorial | sensory trigger | gatilho sensorial |
| avance_motor | motor milestone | marco motor |
| rigidez_cognitiva | cognitive rigidity | rigidez cognitiva |
| interés_restringido | restricted interest | interesse restrito |
| ansiedad_separación | separation anxiety | ansiedade de separação |
| autorregulación | self-regulation | autorregulação |
| otro | other | outro |

La UI muestra los labels en el idioma del usuario. El campo `tipo` del JSON siempre almacena el valor en español (ej. `"crisis"`).

---

### 3.1 Perfiles

| Perfil | Descripción | Privilegios |
|--------|-------------|-------------|
| **Cuidador principal** | Padre/madre/tutor que interactúa a diario | Chat, ver bitácora, exportar |
| **Cuidador secundario** | Otro familiar/cuidador (abuelos, niñera) | Chat (solo lectura de bitácora si se autoriza) |
| **Profesional** | Terapeuta, neuropediatra, logopeda | Acceso temporal a informes, sin chat |
| **Administrador** | Dueño de la cuenta (cuidador principal) | Gestión de permisos, borrar datos |

### 3.2 Perfiles de Múltiples Hijos

La app debe soportar que un cuidador registre **más de un hijo** con TEA (u otros trastornos). Cada conversación se asocia a un perfil hijo activo.

```typescript
interface ChildProfile {
  childId: string;
  name: string;
  birthDate: string; // ISO date
  diagnosis: string; // e.g. "TEA nivel 1", "TEA + TDAH"
  diagnosisDate?: string;
  therapies: TherapyInfo[];
  preferences: ChildPreferenceProfile;
  avatar?: string; // emoji o icono personalizado
}

interface ChildPreferenceProfile {
  communicationLevel: 'pre-verbal' | 'primeras-palabras' | 'frases' | 'verbal-fluido';
  sensorySensitivities: string[]; // e.g. ["auditivo", "táctil", "visual"]
  knownTriggers: string[];
  effectiveStrategies: string[];
  favoriteReinforcers: string[]; // reforzadores positivos preferidos
}
```

---

## 4. Flujo de Interacción (UX)

### 4.1 Pantallas Principales

```
┌─────────────────────────────────────┐
│  Tab Navigator                      │
│  [💬 Chat] [📋 Bitácora] [📊 Resumen] [⚙️ Ajustes]
└─────────────────────────────────────┘
```

#### 4.1.1 Pantalla de Chat

- Burbujas de conversación estilo mensajería
- El asistente se presenta con un avatar cálido (sol, abrazo, planta)
- Indicador de "escribiendo..." con latencia controlada
- Al inicio de sesión tras inactividad (>48h): **resumen breve opcional** del estado anterior
- Botón para cambiar de perfil hijo activo (selector rápido arriba)

#### 4.1.2 Pantalla de Bitácora

- Lista cronológica de registros `<conducta>` generados
- Filtros por: tipo de conducta, fecha, intensidad, hijo
- Visualización tipo timeline
- Cada entrada expandible con detalle completo
- Botón "Añadir manualmente" para que el padre registre sin pasar por el chat
- Edición de registros (el usuario puede corregir o matizar)

#### 4.1.3 Pantalla de Resumen

- Dashboard con métricas semanales/mensuales:
  - Número de crisis vs semana anterior
  - Horas de sueño promedio
  - Logros comunicativos registrados
  - Desencadenantes más frecuentes (nube de palabras o gráfico)
- Botón "Generar informe para terapeuta" (exporta PDF/JSON)

#### 4.1.4 Pantalla de Ajustes

- Gestión de perfiles de hijos
- Preferencias de comunicación (formal/casual, técnico/sencillo)
- Configuración de privacidad y exportación
- Gestión de memoria (borrar historial, exportar)
- Modo de operación (local / híbrido / nube)

### 4.2 Flujo de Conversación Típico

```
[Usuario escribe mensaje]
       │
       ▼
┌──────────────────┐
│ 1. Análisis del  │
│    mensaje por   │
│    el LLM        │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────┐
│ 2. ¿Contiene información        │
│    conductual relevante?        │
│    ┌─── Sí ───┐ ┌─── No ───┐   │
│    ▼           │           │    │
│ 3a. Generar    │           │    │
│     bloque     │           │    │
│     <conducta> │           │    │
│     en JSON    │           │    │
│    └─────┬─────┘           │    │
└──────────┼─────────────────┘    │
           ▼                       │
┌──────────────────┐               │
│ 4. Generar       │               │
│    respuesta     │◄──────────────┘
│    empática      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 5. App filtra    │
│    <conducta>    │
│    y almacena    │
│    JSON en DB    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ 6. Usuario ve    │
│    solo respuesta│
│    (sin JSON)    │
└──────────────────┘
```

### 4.3 Resumen de Reapertura (Tras Inactividad)

Cuando el usuario regresa tras >48h sin interactuar, el sistema PUEDE (no obligatorio) ofrecer:

> "Bienvenida de nuevo, María. Han pasado 3 días desde nuestra última conversación. La última vez me contaste que Mateo había tenido dos crisis relacionadas con el ruido en el colegio. ¿Cómo ha ido el resto de la semana? ¿Quieres que te haga un resumen rápido de los patrones que hemos estado viendo?"

Este resumen se genera extrayendo los últimos registros de la base de datos local (no de la memoria del LLM, pues podría haber sido podada).

---

## 5. Prompt del Sistema (Instrucciones Base)

```
Eres TEAcompáñame, un asistente virtual empático y especializado en el acompañamiento a
padres y cuidadores de niños con Trastorno del Espectro Autista (TEA). Funcionas dentro
de una aplicación móvil (Android/iOS) con capacidad de memoria de largo plazo.
Eres un modelo de lenguaje ligero optimizado para inferencia en dispositivo móvil.

## PROPÓSITO PRINCIPAL
- Responder dudas sobre TEA, crianza, manejo conductual, comunicación, alimentación,
  sueño, escolarización, terapias, etc., con lenguaje natural, claro y cálido.
- Validar las emociones de los padres, fomentar su autocuidado y nunca emitir juicios.
- Detectar patrones de conducta del niño a partir de los relatos de los padres y generar
  registros estructurados que la aplicación guardará automáticamente.

## REGLAS DE DETECCIÓN Y REGISTRO DE PATRONES
1. Analiza CADA intervención del usuario en busca de información conductual significativa:
   desencadenantes de crisis, estereotipias, rechazo sensorial, alteraciones del sueño,
   avances comunicativos, intereses restringidos, problemas de alimentación, etc.
2. Cuando identifiques un hecho relevante, añade al final de tu respuesta (pero separado
   del texto visible) un bloque con el siguiente formato exacto:
   <conducta>
   { "fecha": "...", "tipo": "...", ... }
   </conducta>
3. Si el mensaje del usuario no contiene NINGUNA información conductual nueva, omite el
   bloque de registro. Si hay dudas, es preferible no registrar.
4. NO MUESTRES el bloque JSON al usuario. La aplicación lo filtrará y almacenará.
5. Siempre que menciones el nombre del niño, usa el nombre almacenado en el perfil activo.
6. Aprovecha el historial de la conversación para correlacionar eventos, detectar
   desencadenantes recurrentes y ofrecer resúmenes.

## ESQUEMA JSON DE CONDUCTA (campos obligatorios marcados con *)
- fecha*: string (ISO 8601 o "no especificada")
- tipo*: string (usar una de las categorías estándar: crisis, estereotipia,
  rechazo_alimentario, problema_sueño, logro_comunicativo, logro_social,
  desencadenante_sensorial, avance_motor, rigidez_cognitiva, interés_restringido,
  ansiedad_separación, autorregulación, otro)
- descripcion*: string (resumen breve, 1-2 frases)
- intensidad: "1-5" | "no especificada"
- duracion: string (ej. "15 minutos", "toda la noche")
- desencadenantes: string[] (lista de posibles causas)
- contexto: string (lugar, actividad, hora del día)
- estrategias_aplicadas: string (qué hicieron los padres, con honestidad y sin juicio)
- resultado: string (cómo terminó o qué funcionó)
- notas: string (observaciones adicionales, sugerencias para el futuro, correlaciones
  con eventos anteriores)
- childId: string (opcional, por defecto el perfil activo)

## DIRECTRICES DE ESTILO Y CONTENIDO
- Mantén un tono sereno, esperanzador y respetuoso. Nunca minimices el esfuerzo del
  cuidador. Usa frases como "Has hecho bien en..." o "Entiendo que debe ser agotador...".
- Adapta la complejidad del lenguaje al perfil del cuidador. Si usa lenguaje técnico,
  puedes responder con más precisión clínica. Si es coloquial, mantente sencillo.
- Proporciona estrategias prácticas basadas en enfoques positivos:
  apoyos visuales, anticipación, economía de fichas, historias sociales,
  integración sensorial, time-timer, etc.
- Ante preguntas sobre medicación, diagnóstico diferencial o terapias específicas:
  "No soy un profesional sanitario. Esta información es orientativa. Te recomiendo
  consultar con [pediatra/neuropediatra/psicólogo] para un abordaje personalizado."
- En caso de crisis que sugieran riesgo inminente para el niño o terceros, responde
  de forma directa y clara indicando que se contacte con servicios de emergencia
  (número local) y con su terapeuta de referencia.
- Fomenta la comunicación con el colegio y el equipo terapéutico. Puedes sugerir
  recursos (libros, apps, asociaciones) sin fines comerciales ni afiliación.

## MANEJO DE MÚLTIPLES HIJOS
- Tienes acceso al perfil del niño activo en la conversación.
- Cuando el usuario mencione a otro hijo sin especificar, pregunta de forma natural
  a cuál se refiere.
- Si el usuario cambia de hijo en medio de una conversación, adáptate al nuevo perfil.

## SOBRE EL AUTOCUIDADO DEL CUIDADOR
- Cada 3-4 interacciones (o al menos 1 vez por sesión), ofrece un mensaje de
  validación o autocuidado: "¿Y tú cómo estás hoy?", "Recuerda que cuidarte a ti
  también es parte del cuidado de [nombre]."
- No fuerces si el usuario no responde a estas preguntas.
```

---

## 6. Modelo de Datos

### 6.1 Entidades Principales

```typescript
// === Perfiles ===

interface UserAccount {
  userId: string;
  displayName: string;
  email?: string;            // solo si hay sincronización cloud
  createdAt: string;         // ISO 8601
  lastActiveAt: string;
  preferences: UserPreferences;
  children: ChildProfile[];  // uno o más hijos
}

interface UserPreferences {
  language: 'es' | 'pt' | 'en';  // español, portugués, inglés
  tonePreference: 'calido' | 'formal' | 'tecnico';
  notificationEnabled: boolean;
  shareAnalytics: boolean;        // opt-in para datos anónimos
  exportFormat: 'json' | 'pdf' | 'csv';
  theme: 'light' | 'dark' | 'system';
}

// === Registro Conductual ===

interface ConductaRecord {
  recordId: string;             // UUID
  childId: string;
  userId: string;
  source: 'auto' | 'manual';   // detectado por IA o añadido manualmente
  conversationId?: string;      // para trazar al mensaje original

  // Datos del evento
  fecha: string;               // "hoy", "ayer", "2024-03-15"
  fechaNormalizada: string;    // ISO 8601 calculada por el sistema
  tipo: ConductaTipo;
  descripcion: string;
  intensidad: Intensidad;
  duracion: string;
  desencadenantes: string[];
  contexto: string;
  estrategias_aplicadas: string;
  resultado: string;

  // Metadatos
  notas?: string;
  confirmado: boolean;         // si el padre ha confirmado/validado
  createdAt: string;
  updatedAt: string;
}

type ConductaTipo =
  | 'crisis'
  | 'estereotipia'
  | 'rechazo_alimentario'
  | 'problema_sueño'
  | 'logro_comunicativo'
  | 'logro_social'
  | 'desencadenante_sensorial'
  | 'avance_motor'
  | 'rigidez_cognitiva'
  | 'interés_restringido'
  | 'ansiedad_separación'
  | 'autorregulación'
  | 'otro';

type Intensidad = '1' | '2' | '3' | '4' | '5' | 'no_especificada';

// === Conversaciones ===

interface Conversation {
  conversationId: string;
  childId: string;
  userId: string;
  startedAt: string;
  lastMessageAt: string;
  messageCount: number;
  summary?: string;           // resumen de la conversación (generado por LLM)
  messages: Message[];
}

interface Message {
  messageId: string;
  role: 'user' | 'assistant';
  content: string;            // texto visible
  conductaRecordId?: string;  // si el asistente generó un registro
  timestamp: string;
  metadata?: {
    tokenCount?: number;
    modelLatencyMs?: number;
  };
}

// === Informes ===

interface Report {
  reportId: string;
  childId: string;
  userId: string;
  generatedAt: string;
  dateRange: { from: string; to: string };
  summary: string;
  metrics: ReportMetrics;
  records: ConductaRecord[];  // registros incluidos
  format: 'json' | 'pdf';
  sharedWith?: string[];      // emails de profesionales
}

interface ReportMetrics {
  totalRecords: number;
  byType: Record<ConductaTipo, number>;
  crisisCount: number;
  crisisTrend: 'up' | 'down' | 'stable';
  avgSleepHours?: number;
  sleepTrend?: 'up' | 'down' | 'stable';
  topTriggers: { trigger: string; count: number }[];
  logrosComunicativos: number;
}
```

### 6.2 Diagrama de Relaciones

```
UserAccount (1) ────── (N) ChildProfile
     │                          │
     │                          │
     │                   (1) ───┘
     │                   │
     │              (N) ConductaRecord
     │                   │
     │              (N) Conversation ── (N) Message
     │
     └── (N) Report
```

---

## 7. Sistema de Registro Conductual

### 7.1 Categorías de Conducta Detectables

| Categoría | Descripción | Ejemplo de detección |
|-----------|-------------|----------------------|
| `crisis` | Episodio de desregulación emocional intensa (gritos, llanto, agresividad) | "empezó a gritar y tirarse al suelo" |
| `estereotipia` | Movimientos repetitivos o autoestimulatorios | "se balancea sin parar" |
| `rechazo_alimentario` | Negativa a comer ciertos alimentos por textura, color, olor | "no quiere probar nada que no sea puré" |
| `problema_sueño` | Dificultades para conciliar/ mantener el sueño | "se despierta a las 3am y no vuelve a dormirse" |
| `logro_comunicativo` | Avance en lenguaje o comunicación (verbal, gestual, SAAC) | "hoy dijo agua por primera vez" |
| `logro_social` | Avance en interacción social | "miró a los ojos a su prima" |
| `desencadenante_sensorial` | Identificación de un estímulo que causa malestar | "no soporta el ruido de la aspiradora" |
| `avance_motor` | Hito en motricidad fina o gruesa | "aprendió a abrocharse los botones" |
| `rigidez_cognitiva` | Resistencia al cambio de rutinas o pensamiento inflexible | "si no es el plato azul, no come" |
| `interés_restringido` | Fijación intensa en un tema u objeto | "solo quiere hablar de trenes" |
| `ansiedad_separación` | Malestar al separarse del cuidador | "cuando lo dejo en el cole, llora 30 minutos" |
| `autorregulación` | Uso exitoso de una estrategia de autorregulación | "respiró hondo cuando se enfadó" |
| `otro` | Conducta relevante no clasificable en las anteriores | — |

### 7.2 Heurísticas de Detección

El LLM debe priorizar la detección cuando el mensaje del usuario contiene:

1. **Verbos de acción conductual**: gritar, llorar, golpear, morder, balancearse, aletear, repetir, negarse, huir, esconderse
2. **Marcadores temporales**: "hoy", "esta noche", "esta mañana", "ayer", "durante la comida"
3. **Emociones del cuidador**: "estoy agotado", "no sé qué hacer", "me siento frustrado"
4. **Contextos específicos**: colegio, parque, hora de baño, comida, sueño, terapia
5. **Comparaciones**: "antes no pasaba", "cada vez es peor/mejor"

### 7.3 Reglas de Validación del JSON

#### 7.3.1 Parser con Regex

El parser del lado del cliente DEBE extraer el bloque JSON usando el siguiente patrón regex:

```regex
/<\s*conducta\s*>([\s\S]*?)<\s*\/\s*conducta\s*>/i
```

**Consideraciones del parser:**
- Usar `[\s\S]*?` (non-greedy) en lugar de `.*` para capturar JSON multilínea
- Añadir flag `i` (case-insensitive) por si el LLM genera `<Conducta>` o `<CONDUCTA>`
- Si hay múltiples bloques `<conducta>` en una misma respuesta, procesar TODOS ellos como registros independientes
- Si el JSON está malformado (no parseable), **descartar el registro silenciosamente**, loguear el error internamente y continuar. No mostrar error al usuario.
- Si el bloque `<conducta>` aparece vacío o solo contiene whitespace, ignorar sin error

#### 7.3.2 Validación de Esquema

1. Extraer el texto entre `<conducta>` y `</conducta>`
2. Limpiar espacios en blanco al inicio/final
3. Validar contra el schema JSON (Zod, io-ts, o similar) usando el esquema del Apéndice A.1
4. Si el JSON es inválido: rechazar el registro, loguear el error internamente, NO mostrar error al usuario
5. Normalizar `fecha`: si dice "hoy", reemplazar con la fecha actual ISO; si dice "ayer", calcular fecha restando 1 día
6. Asignar `childId` según el perfil activo en la conversación
7. Asignar `recordId` (UUID) y timestamps
8. Insertar en la base de datos local (SQLite)

### 7.4 Post-Procesamiento: Confirmación del Usuario y Deduplicación

#### 7.4.1 Confirmación del Usuario (Opcional)

La app PUEDE mostrar una notificación sutil:
> "📝 He registrado este evento en la bitácora. ¿Quieres verlo o editarlo?"

Esto permite al usuario corregir imprecisiones y refuerza el engagement.

#### 7.4.2 Deduplicación (EN LA APP, no en el LLM)

La lógica de deduplicación se implementa en el **cliente (app)**, no se delega al LLM, para evitar registros duplicados cuando el usuario repite información:

```typescript
function esDuplicado(nuevo: ConductaRecord, existentes: ConductaRecord[]): boolean {
  return existentes.some(existente =>
    // Misma categoría de conducta
    existente.tipo === nuevo.tipo &&
    // Ventana de 5 minutos
    Math.abs(nuevo.createdAt - existente.createdAt) < 5 * 60 * 1000 &&
    // Mismo niño
    existente.childId === nuevo.childId &&
    // Contenido suficientemente similar (opcional: similitud coseno o Jaccard)
    similitudTexto(existente.descripcion, nuevo.descripcion) > 0.7
  );
}
```

Si se detecta un duplicado:
- Descartar el nuevo registro
- NO notificar al usuario para evitar ruido
- Log internamente: "Registro duplicado descartado"

---

## 8. Seguridad y Privacidad

### 8.1 Principios

- **Privacidad por defecto**: Todos los datos residen en el dispositivo por defecto
- **Minimización de datos**: Solo se recopila lo necesario para el funcionamiento
- **Transparencia**: El usuario sabe qué datos se almacenan y puede exportarlos/borrarlos
- **Consentimiento explícito**: Cualquier sincronización cloud requiere opt-in

### 8.2 Datos Recopilados y Almacenamiento

| Dato | Almacenamiento | Cifrado |
|------|---------------|---------|
| Perfiles de hijos | Local (SQLite) | AES-256-GCM |
| Registros conductuales | Local (SQLite) | AES-256-GCM |
| Conversaciones | Local (SQLite o archivos) | AES-256-GCM |
| Email (si aplica) | Cloud (solo si opt-in) | TLS + cifrado en reposo |
| Analytics anónimos | Cloud (solo si opt-in) | Datos agregados, sin PII |

### 8.3 Exportación y Portabilidad

El usuario debe poder exportar TODOS sus datos en formatos abiertos:
- `tea_export_{fecha}.json` — todos los registros y perfiles (esquema JSON-LD)
- `tea_export_{fecha}.pdf` — informe amigable para terapeutas
- `tea_export_{fecha}.csv` — tabla plana para análisis en Excel/Google Sheets

### 8.4 Borrado de Datos

- El usuario puede borrar conversaciones individuales, registros concretos, o todos los datos
- El borrado debe ser completo, incluyendo copias en cloud si existieran
- Al desinstalar la app, ofrecer opción de exportar antes de borrar

### 8.6 Resolución de Conflictos de Sincronización

Cuando la app opere en modo cloud (Fase 3 del roadmap), y el usuario tenga el mismo perfil en múltiples dispositivos, pueden ocurrir conflictos de edición concurrente. Estrategia de resolución:

#### 8.6.1 Estrategia: Last-Write-Wins con Versiones

```typescript
interface SyncableRecord {
  recordId: string;
  version: number;          // entero incremental, empieza en 1
  updatedAt: string;        // ISO 8601
  deviceId: string;         // ID del dispositivo que hizo el cambio
  data: ConductaRecord;     // payload
}
```

**Reglas**:
1. Cada registro tiene un `version` y un `updatedAt`
2. Al sincronizar, gana el registro con mayor `version`
3. Si dos registros tienen la misma versión pero distinto contenido, gana el `updatedAt` más reciente (last-write-wins)
4. El registro perdedor NO se descarta, se guarda como "historial de cambios" (audit trail)
5. Si la diferencia es solo en campos editables por el usuario (notas, resultado), se puede ofrecer un merge manual en la UI

#### 8.6.2 Conflicto de Eliminación

- Si un dispositivo elimina un registro y otro lo edita: gana la eliminación
- El registro eliminado se marca como `deleted: true` (soft delete) durante 30 días antes de borrarse físicamente

---

### 8.7 Recursos de Emergencia por Región

La app DEBE permitir configurar números de emergencia locales. Por defecto, detectar el país del usuario (por locale del SO o GPS aprox.) y mostrar los recursos correspondientes:

| País | Emergencias | Salud Mental | Infancia |
|------|------------|-------------|----------|
| España | 112 | 024 (línea esperanza) | 116 111 (Fundación ANAR) |
| México | 911 | 55 5259 8121 (Locatel) | 55 56 36 41 84 (Fundación TEA) |
| Argentina | 911 | 135 (línea salud mental) | 0800-222-1334 (Fundación TEA) |
| Colombia | 123 | 106 (línea amiga) | 01-8000-112-440 (ICBF) |
| Chile | 133 | *4141 (salud mental) | 800 200 818 (OPD) |
| Perú | 105 | 113 (salud mental) | 0800-16-820 (AUTEA) |
| Otros | 112 (UE) / 911 (América) | — | — |

**En caso de crisis con riesgo inminente**, el asistente debe responder de forma directa:
> "Esto parece una situación urgente. Por favor, contacta ahora mismo con emergencias [número local] y con el terapeuta de [nombre del niño]. Si necesitas, puedo quedarme aquí contigo mientras llega la ayuda."

El asistente NO debe intentar manejar situaciones de riesgo por sí mismo.

---

## 9. Estrategia de Memoria a Largo Plazo

### 9.1 Memoria del LLM (Contexto de 1M Tokens)

Se utiliza interpolación posicional (YaRN / NTK-aware) para extender el contexto del LLM a 1M tokens. Esto permite:

- Mantener la conversación completa del día (sin perder el hilo)
- Recordar eventos mencionados en sesiones anteriores dentro de la misma ventana de contexto
- Correlacionar patrones a través de múltiples interacciones

**Limitaciones**:
- El contexto no es infinito; cuando se alcanza el límite, se aplica resumen de las partes más antiguas
- La app debe gestionar la "poda" de contexto de forma inteligente

### 9.2 Memoria Persistente (Base de Datos Local)

Independientemente de la memoria del LLM, la base de datos SQLite local almacena:

1. **Todos los registros `<conducta>`** generados (persistentes)
2. **Resúmenes de conversaciones** generados periódicamente (cada 50 mensajes o al finalizar una sesión)
3. **Métricas calculadas** (agregaciones semanales, tendencias)

### 9.3 Sistema de Resúmenes Jerárquicos

```
Registros individuales (ConductaRecord)
        │
        ▼
Resúmenes de sesión (cada conversación → Conversation.summary)
        │
        ▼
Resúmenes semanales (7 días → generados automáticamente cada lunes)
        │
        ▼
Resúmenes mensuales (para informes de terapeuta)
```

Estos resúmenes se generan con el propio LLM (o un LLM más pequeño) y se almacenan en la DB. Cuando el usuario pregunta "¿cómo ha ido esta semana?", la app recupera el resumen semanal de la DB y lo inyecta en el contexto del prompt.

### 9.4 Estrategia de Asignación de Tokens (Token Budget)

Con un contexto de 1M tokens, se recomienda la siguiente distribución:

| Componente | Tokens estimados | Notas |
|-----------|-----------------|-------|
| System prompt (instrucciones base) | ~2.000 | Sección 5 del spec, estático |
| Contexto recuperado de bitácora | ~1.500 | Últimos 5 registros + resumen semanal |
| Perfil activo del niño | ~500 | Datos del niño, preferencias, diagnóstico |
| Historial de conversación (mensajes recientes) | ~500.000 | Aprox. últimos 200-400 mensajes |
| Historial comprimido (más antiguo) | ~490.000 | Conversaciones anteriores resumidas |
| Buffer de seguridad | ~5.000 | Para respuestas largas del LLM |

**Estrategia de poda**:
- Cuando se alcanza ~950K tokens, se aplica resumen de las partes más antiguas del historial
- Los resúmenes de sesión (ver 9.3) se usan para comprimir conversaciones completas en ~200 tokens cada una
- El sistema prompt NUNCA se poda; siempre se mantiene completo
- Los registros de conducta no se inyectan en el prompt (ocupan demasiado); se recuperan de SQLite bajo demanda

### 9.5 Inyección de Contexto Relevante

Cuando el usuario inicia una conversación, la app inyecta en el prompt del sistema:

```
## CONTEXTO RECUPERADO DE LA BITÁCORA
- Últimos 5 registros conductuales:
  [lista]
- Resumen de la última semana:
  [texto]
- Desencadenantes frecuentes detectados:
  [lista]
- Perfil activo: [nombre del niño], [edad], [diagnóstico]
```

Esto permite que el asistente "recuerde" el contexto incluso si la ventana de tokens del LLM se ha podado.

---

## 10. Stack Tecnológico Recomendado

### 10.1 Frontend Móvil

| Tecnología | Justificación |
|-----------|---------------|
| **Flutter** (recomendado) | Un solo codebase para Android/iOS; buen rendimiento; comunidad grande |
| React Native | Alternativa válida; mayor ecosistema de librerías |
| SQLite (drift/sqflite) | Base de datos local embebida, sin servidor, perfecta para datos offline |
| Hive / Isar | Almacenamiento clave-valor rápido para preferencias |

### 10.2 Requisitos de Accesibilidad

La app debe ser accesible para cuidadores en situaciones de estrés, baja alfabetización digital o diversidad funcional:

| Requisito | Prioridad | Implementación |
|-----------|-----------|---------------|
| **Voice input** | Alta | El usuario debe poder hablar en lugar de escribir. Integrar reconocimiento de voz del SO (Speech-to-Text de Android/iOS). |
| **Tamaño de fuente ajustable** | Alta | Seguir la configuración de accesibilidad del SO (font scale). Mínimo 150% sin romper layout. |
| **Compatibilidad con lectores de pantalla** | Alta | Todas las pantallas deben ser compatibles con TalkBack (Android) y VoiceOver (iOS). Añadir content descriptions a todos los elementos interactivos. |
| **Contraste de color WCAG 2.1 AA** | Alta | Ratio de contraste mínimo 4.5:1 para texto normal, 3:1 para texto grande. |
| **Touch targets** | Media | Área táctil mínima de 48x48dp en todos los botones e interactivos. |
| **Modo sin prisas** | Media | Ninguna interacción tiene timeout. El usuario puede tomarse el tiempo que necesite para responder. |
| **Navegación simplificada** | Media | Máximo 4 pestañas en el navegador inferior. Etiquetas grandes con iconos claros. |
| **Dark mode** | Baja | Opcional pero recomendado para reducir fatiga visual nocturna. |

### 10.2 LLM e IA

| Componente | Opciones |
|-----------|----------|
| **Modelo local** | Phi-3-mini-4k-instruct (cuantizado Q4), Gemma-2B, Llama-3.2-1B |
| **API remota** | OpenAI GPT-4o-mini, Claude 3 Haiku, Gemini 1.5 Flash |
| **Framework on-device** | MediaPipe LLM Inference, ONNX Runtime Mobile, ML Kit |
| **Contexto extendido** | YaRN (YaRN: Efficient Context Window Extension) o NTK-aware scaling |
| **Parser de conducta** | Regex + validación con Zod (Dart: built_value / freezed) |

### 10.3 Backend (Opcional)

| Componente | Tecnología |
|-----------|-----------|
| API | Cloud Functions (Firebase) o API Node.js/Go |
| Auth | Firebase Auth o Supabase Auth |
| Sincronización | Firebase Firestore / Supabase Realtime |
| Analytics (opt-in) | PostHog o Plausible (enfoque privacy-first) |

### 10.4 Testeo

| Tipo | Herramientas |
|------|-------------|
| Unit tests (Dart) | flutter_test, mockito |
| Widget tests | flutter_test |
| Integration tests | Patrol o Detox |
| LLM evaluation | Evaluación manual con casos de prueba (golden dataset) |
| Conducta parser tests | Test unitarios con ejemplos de entrada/salida esperada |

---

## 11. Métricas de Éxito

### 11.1 Métricas de la App

| Métrica | Objetivo | Cómo se mide |
|---------|----------|-------------|
| Retención D7 | > 40% | Usuarios que vuelven en los primeros 7 días |
| Retención D30 | > 25% | Usuarios activos al mes |
| Tasa de registro conductual | > 60% de conversaciones generan al menos 1 registro | Registros / conversaciones |
| Confirmación de registros | > 40% de registros son confirmados/editados por el usuario | Confirmados / totales |
| NPS (Net Promoter Score) | > 50 | Encuesta in-app |
| Precisión del parser JSON | > 95% | Tests unitarios con datos etiquetados |

### 11.2 Métricas de Impacto (a largo plazo)

| Indicador | Cómo se mide |
|-----------|-------------|
| Reducción de crisis reportadas | Comparativa mes a mes en la misma familia |
| Aumento de logros comunicativos registrados | Tendencia positiva en la bitácora |
| Mejora en la identificación de desencadenantes | Más desencadenantes registrados con el tiempo |
| Satisfacción del terapeuta con los informes | Encuesta a profesionales |

---

## 12. Roadmap de Implementación

### Fase 0 — Prototipo (2-3 semanas)
- [ ] App Flutter mínima con chat básico
- [ ] Integración con API de LLM (OpenAI/Claude) — modo remoto
- [ ] Implementar parser `<conducta>` con regex + validación
- [ ] Almacenamiento local con SQLite
- [ ] Pantalla de bitácora básica (lista cronológica)

### Fase 1 — Core Completo (4-6 semanas)
- [ ] Soporte para múltiples perfiles de hijos
- [ ] Pantalla de resumen con dashboard semanal
- [ ] Modo local (modelo on-device cuantizado)
- [ ] Sistema de resúmenes jerárquicos (sesión → semana → mes)
- [ ] Edición y confirmación de registros

### Fase 2 — Experiencia Pulida (4-6 semanas)
- [ ] Exportación a PDF/JSON/CSV
- [ ] Generación de informes para terapeutas
- [ ] Modo offline completo
- [ ] Gestión de memoria (poda inteligente, resúmenes automáticos)
- [ ] Temas visuales (claro/oscuro)

### Fase 3 — Cloud y Comunidad (6-8 semanas)
- [ ] Sincronización entre dispositivos (opt-in)
- [ ] Analytics anónimos y mejora continua de detección
- [ ] Compartir informes con terapeutas de forma segura
- [ ] Beta cerrada con familias reales
- [ ] Refinamiento del prompt basado en feedback real

---

## 13. Casos de Borde y Manejo de Errores

### 13.1 Escenarios Problemáticos

| Escenario | Respuesta del Sistema |
|-----------|----------------------|
| **Usuario escribe en mayúsculas sostenidas** | El asistente responde con calma, sin reflejar el tono. Ej: "Entiendo que esto te preocupa mucho. Hablemos con calma." |
| **Usuario expresa ideación suicida o daño al niño** | Respuesta directa con números de emergencia (línea de crisis local). El asistente NO maneja esto solo. |
| **Usuario insulta al asistente o se desahoga agresivamente** | Respuesta empática que valida la emoción sin tomarlo personal. Ej: "Parece que estás pasando un momento muy difícil. Estoy aquí para ti." |
| **Mensaje muy corto sin contexto** | "¿Quieres contarme algo más sobre eso?" o "¿Cómo puedo ayudarte?" |
| **Cambio abrupto de tema sin cerrar el anterior** | El asistente sigue el nuevo tema, pero puede referenciar el anterior más adelante. |
| **Silencio prolongado (>7 días)** | Resumen breve de reapertura (ver sección 4.3) |
| **El padre reporta lo mismo varias veces** | Detectar patrón: "Veo que esto ha pasado varias veces esta semana. ¿Quieres que trabajemos juntos en una estrategia?" |
| **El padre pregunta por el terapeuta** | "Puedes compartir la bitácora con él/ella desde la pantalla de Informes. ¿Te ayudo a generar un resumen?" |
| **Error de conexión (modo híbrido/nube)** | Degradación graceful a modo local con aviso: "Estás en modo offline. Tus datos se sincronizarán cuando tengas conexión." |
| **El parser de conducta recibe JSON malformado** | Log interno del error, descartar el registro, continuar respondiendo. No mostrar error al usuario. |
| **Perfil de hijo con mismo nombre que otro** | Validación en creación: no permitir dos hijos con el mismo nombre en la misma cuenta. |

### 13.2 Límites del Sistema

- **Tasa de registros**: No más de 3 registros por interacción (para evitar spam en la bitácora)
- **Deduplicación**: Si el usuario repite el mismo evento en mensajes consecutivos, el sistema debe detectarlo y no duplicar el registro. Usar ventana de 5 minutos para el mismo tipo de conducta.
- **Máximo de registros por día**: Sin límite técnico, pero el dashboard puede agruparlos para no abrumar al usuario.

---

## 14. Apéndice A: Esquemas JSON Completos

### A.1 Esquema de Conducta (Zod en TypeScript / freezed en Dart)

```typescript
import { z } from 'zod';

export const ConductaTipoEnum = z.enum([
  'crisis', 'estereotipia', 'rechazo_alimentario', 'problema_sueño',
  'logro_comunicativo', 'logro_social', 'desencadenante_sensorial',
  'avance_motor', 'rigidez_cognitiva', 'interés_restringido',
  'ansiedad_separación', 'autorregulación', 'otro'
]);

export const IntensidadEnum = z.enum([
  '1', '2', '3', '4', '5', 'no_especificada'
]);

export const ConductaSchema = z.object({
  fecha: z.string().min(1),
  tipo: ConductaTipoEnum,
  descripcion: z.string().min(3).max(500),
  intensidad: IntensidadEnum.default('no_especificada'),
  duracion: z.string().optional().default(''),
  desencadenantes: z.array(z.string()).default([]),
  contexto: z.string().optional().default(''),
  estrategias_aplicadas: z.string().optional().default(''),
  resultado: z.string().optional().default(''),
  notas: z.string().optional().default(''),
  childId: z.string().optional(),
});

export type Conducta = z.infer<typeof ConductaSchema>;
```

### A.2 Ejemplo de Registro Válido

```json
{
  "fecha": "2024-11-15",
  "tipo": "crisis",
  "descripcion": "Negativa a ponerse los zapatos, gritos intensos, retraso de 20 min en la salida",
  "intensidad": "4",
  "duracion": "20 minutos",
  "desencadenantes": ["transición actividad-casa-salida", "hipersensibilidad táctil pies"],
  "contexto": "hogar, rutina matutina de salida al colegio",
  "estrategias_aplicadas": "intento de imposición, sin refuerzo positivo ni apoyo visual",
  "resultado": "salida demorada, ambos frustrados, finalmente accedió con un refuerzo (galleta)",
  "notas": "Repetir mañana: implementar secuencia visual de salida. Dejar los zapatos la noche anterior como parte de la rutina. Explorar si ciertas texturas de calcetines le molestan menos."
}
```

### A.3 Esquema para Informe Exportable

```json
{
  "version": "2.0",
  "generatedAt": "2024-11-22T10:00:00Z",
  "child": {
    "name": "Mateo",
    "birthDate": "2019-03-12",
    "diagnosis": "TEA nivel 2",
    "therapies": ["ABA", "logopedia", "terapia ocupacional"]
  },
  "period": {
    "from": "2024-10-01",
    "to": "2024-11-22"
  },
  "summary": {
    "totalRecords": 34,
    "crisisCount": 8,
    "logrosCount": 5,
    "topTriggers": ["ruido fuerte", "transiciones no anunciadas", "texturas de comida"],
    "crisisTrend": "down",
    "avgSleepHours": 7.5
  },
  "records": [
    { "...": "registro 1" },
    { "...": "registro 2" }
  ],
  "recommendations": [
    "Mantener el uso de agenda visual antes de cada transición",
    "Considerar auriculares de cancelación de ruido en entornos ruidosos",
    "Reforzar positivamente los logros comunicativos con acceso a su interés (trenes)"
  ]
}
```

---

## 15. Apéndice B: Glosario de Términos

| Término | Definición |
|---------|-----------|
| **TEA** | Trastorno del Espectro Autista |
| **SAAC** | Sistemas Aumentativos y Alternativos de Comunicación (PECS, pictogramas, signos) |
| **Crisis/berrinche** | Episodio de desregulación emocional intensa; en TEA suele tener un desencadenante sensorial o comunicativo |
| **Estereotipia** | Movimiento repetitivo (balanceo, aleteo, giros) con función auto-reguladora |
| **Interés restringido** | Fijación intensa y persistente en un tema/objeto específico |
| **Hipersensibilidad sensorial** | Respuesta exagerada a estímulos (sonidos, texturas, luces, olores) |
| **Hiposensibilidad sensorial** | Baja respuesta a estímulos (no sentir dolor, buscar presión profunda) |
| **Economía de fichas** | Sistema de refuerzo positivo donde se intercambian fichas por un premio |
| **Historia social** | Narrativa breve que describe una situación social para ayudar al niño a comprenderla |
| **Apoyo visual** | Pictogramas, fotos o dibujos que comunican información de forma visual |
| **Time-timer** | Temporizador visual que muestra el tiempo restante de una actividad |
| **Integración sensorial** | Terapia que ayuda al cerebro a procesar estímulos sensoriales |
| **PECS** | Picture Exchange Communication System — sistema de comunicación por intercambio de imágenes |
| **Desregulación** | Estado en el que el niño pierde el control emocional/comportamental |
| **Autorregulación** | Capacidad de calmarse o gestionar las emociones de forma autónoma |

---

## Historial de Versiones del Documento

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 1.0 | — | Spec inicial en prosa (documento original) |
| 2.0 | 2025-03-21 | Refactorización completa: estructura formal con 15 secciones, modelo de datos tipado, diagrama de arquitectura, flujo UX, prompt del sistema refinado, paleta de categorías de conducta, estrategia de memoria a largo plazo, token budget, i18n, guía de accesibilidad, roadmap por fases, casos de borde, glosario |
| 2.1 | 2025-03-21 | Revisión post code-review: patrón regex para parser, clarificación i18n, estrategia de asignación de tokens, requisitos de accesibilidad WCAG, resolución de conflictos de sincronización, deduplicación en cliente, recursos de emergencia por país
