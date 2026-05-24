# TEAcompáñame 🧩

Asistente inteligente con IA para el acompañamiento terapéutico de personas con Trastorno del Espectro Autista (TEA).

## Descripción

TEAcompáñame es una aplicación móvil que utiliza Inteligencia Artificial (LLMs) para ayudar a padres, cuidadores y terapeutas en el registro, análisis y seguimiento de conductas relacionadas con el TEA. La app permite:

- 💬 **Chat conversacional**: Interactúa naturalmente describiendo situaciones o conductas observadas
- 📝 **Registro automático**: La IA detecta y registra automáticamente conductas relevantes en la bitácora
- 📊 **Bitácora digital**: Visualiza todos los registros históricos filtrables por fecha y tipo
- 👤 **Múltiples perfiles**: Gestiona varios niños/pacientes con configuraciones individualizadas
- 🔒 **Privacidad garantizada**: Los datos se almacenan localmente (SQLite/SharedPreferences)

## Características Principales

### ✅ Implementadas
- Parser inteligente de bloques `<conducta>` en respuestas de IA
- Sistema de deduplicación de registros (evita duplicados por fecha/tipo/descripción)
- Almacenamiento dual: SQLite (nativo) / SharedPreferences (web)
- Validación de esquemas JSON para registros de conducta
- 13 tipos de conducta predefinidos (crisis, logros, estereotipias, etc.)
- Normalización automática de fechas ("hoy", "ayer" → ISO 8601)
- Modo demo sin configuración de API
- Soporte multiplataforma: Android, iOS, Web

### 🚀 Próximas Mejoras (Roadmap)
- [ ] Tests unitarios completos (parser, storage, servicios)
- [ ] Gestión de estado con Provider/Riverpod
- [ ] Cifrado de base de datos local (SQLCipher)
- [ ] Internacionalización (i18n) - español/inglés
- [ ] Accesibilidad WCAG completa
- [ ] Sistema de retry con backoff exponencial para LLM
- [ ] Exportación de datos a PDF/CSV
- [ ] Gráficos y estadísticas avanzadas

## Arquitectura

```
lib/
├── main.dart                 # Punto de entrada, configuración de tema
├── models/                   # Modelos de datos
│   ├── conducta_record.dart  # Registro de conducta (schema completo)
│   ├── message.dart          # Mensajes de chat
│   ├── child_profile.dart    # Perfiles de niños/pacientes
│   └── api_config.dart       # Configuración de API LLM
├── screens/                  # Pantallas principales
│   ├── chat_screen.dart      # Chat con IA + registro automático
│   ├── log_screen.dart       # Bitácora de registros
│   ├── config_screen.dart    # Configuración de API
│   └── children_screen.dart  # Gestión de perfiles
├── services/                 # Servicios y lógica de negocio
│   ├── llm_service.dart      # Integración con APIs de IA (OpenAI, Gemini, Ollama)
│   ├── storage_service.dart  # Almacenamiento dual + deduplicación
│   ├── export_service.dart   # Exportación a PDF/CSV
│   └── file_saver*.dart      # Guardado de archivos (web/nativo)
└── widgets/                  # Componentes reutilizables
    ├── conducta_parser.dart  # Parser regex de bloques <conducta>
    └── record_card.dart      # Cards para visualización de registros
test/                         # Tests unitarios
├── parser_test.dart          # Tests del parser de conductas
└── storage_test.dart         # Tests de almacenamiento y deduplicación
```

## Instalación

### Requisitos Previos
- Flutter SDK ≥ 3.0
- Dart ≥ 2.17
- Para Android: Android Studio + emulador/dispositivo físico
- Para iOS: Xcode (macOS) + simulador/dispositivo físico
- Para Web: Navegador moderno (Chrome, Firefox, Edge)

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/tea_companame.git
   cd tea_companame
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar API (opcional)**
   
   La app incluye un modo demo que no requiere configuración. Para usar IA real:
   
   - **OpenAI**: Obtén una API key en https://platform.openai.com/api-keys
   - **Google Gemini**: Obtén una API key en https://makersuite.google.com/app/apikey
   - **Ollama (local)**: Instala desde https://ollama.ai y ejecuta `ollama run llama3`

4. **Ejecutar la aplicación**
   ```bash
   # Android
   flutter run
   
   # iOS
   flutter run -d ios
   
   # Web
   flutter run -d chrome
   
   # Build de producción
   flutter build apk --release
   flutter build web --release
   ```

## Uso

### Primeros Pasos

1. **Seleccionar niño/paciente**: En la pantalla de inicio, crea o selecciona un perfil existente
2. **Configurar API (opcional)**: Ve a Configuración → API e ingresa tu clave
3. **Iniciar conversación**: Describe una situación o conducta observada
4. **Revisar registros**: La IA registrará automáticamente las conductas detectadas
5. **Explorar bitácora**: Ve a la pestaña "Bitácora" para ver el histórico

### Ejemplo de Uso

```
Usuario: "Hoy Lucas tuvo una crisis fuerte en el supermercado porque 
         cambiaron la disposición de los productos. Gritó durante 10 minutos."

IA: [Procesa la descripción]
    [Genera bloque <conducta> interno]
    [Guarda registro automáticamente]
    
Respuesta visible: "Entiendo que fue una situación difícil. Los cambios 
                    en el entorno pueden ser desencadenantes comunes..."
```

### Tipos de Conducta Soportados

| Tipo | Descripción |
|------|-------------|
| `crisis` | Episodios de desregulación emocional/motora |
| `estereotipia` | Movimientos o vocalizaciones repetitivas |
| `rechazo_alimentario` | Negativa a comer ciertos alimentos |
| `problema_sueño` | Dificultades para dormir o mantener el sueño |
| `logro_comunicativo` | Nuevas formas de comunicación adquiridas |
| `logro_social` | Mejoras en interacción social |
| `desencadenante_sensorial` | Reacciones a estímulos sensoriales |
| `avance_motor` | Nuevas habilidades motoras desarrolladas |
| `rigidez_cognitiva` | Resistencia a cambios o rutinas diferentes |
| `interés_restringido` | Focalización intensa en temas específicos |
| `ansiedad_separación` | Angustia al separarse de figuras de apego |
| `autorregulación` | Estrategias exitosas de calma propia |
| `otro` | Conductas que no encajan en otras categorías |

## Tecnologías Utilizadas

- **Flutter** - Framework UI multiplataforma
- **Dart** - Lenguaje de programación
- **SQLite** - Base de datos local (nativo)
- **SharedPreferences** - Almacenamiento web
- **HTTP** - Cliente para APIs REST
- **Provider** - Gestión de estado (pendiente)
- **PDF** - Generación de reportes (pendiente)

## Privacidad y Seguridad

- ✅ Todos los datos se almacenan **localmente** en el dispositivo
- ✅ No se envía información a servidores externos (excepto consultas a API LLM configurada)
- ✅ Sin tracking ni analytics de terceros
- ✅ Código abierto y auditable

⚠️ **Importante**: Las consultas a APIs de IA (OpenAI, Gemini, etc.) están sujetas a sus respectivas políticas de privacidad. Para máxima privacidad, usa Ollama en local.

## Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Haz fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## License

Este proyecto está bajo la licencia MIT. Ver archivo `LICENSE` para más detalles.

## Contacto

- 📧 Email: tu-email@ejemplo.com
- 🐛 Issues: https://github.com/tu-usuario/tea_companame/issues
- 📖 Documentación: https://github.com/tu-usuario/tea_companame/wiki

---

**Nota**: Esta aplicación es una herramienta de apoyo y **no reemplaza** el seguimiento profesional de especialistas en TEA.
