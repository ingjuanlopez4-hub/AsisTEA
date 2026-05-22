import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../models/message.dart';
import '../models/child_profile.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/child_selector.dart';
import '../widgets/conducta_parser.dart';
import '../services/llm_service.dart';
import '../services/storage_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;
  bool _isInitialized = false;

  // Perfiles de hijos (mock data para el prototipo)
  List<ChildProfile> _children = [];
  ChildProfile? _activeChild;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Cargar perfiles o crear uno por defecto
    final profiles = await _storage.getChildProfiles();
    if (profiles.isEmpty) {
      final defaultChild = ChildProfile(
        childId: _uuid.v4(),
        name: 'Mateo',
        birthDate: '2019-03-12',
        diagnosis: 'TEA nivel 2',
        communicationLevel: 'frases',
        sensorySensitivities: ['auditivo', 'táctil'],
        knownTriggers: ['ruidos fuertes', 'transiciones no anunciadas'],
        effectiveStrategies: ['apoyos visuales', 'anticipación'],
        favoriteReinforcers: ['trenes', 'galletas'],
        avatar: '🌟',
      );
      await _storage.insertChildProfile(defaultChild);
      _children = [defaultChild];
    } else {
      _children = profiles;
    }

    // Cargar mensajes previos
    final savedMessages = await _storage.getMessages();
    if (savedMessages.isNotEmpty) {
      _messages.addAll(savedMessages);
    } else {
      // Mensaje de bienvenida
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        role: 'assistant',
        content:
            '¡Hola! Soy TEAcompáñame. Estoy aquí para escucharte y acompañarte en el día a día con ${_children.first.name}. Cuéntame, ¿cómo ha ido todo?',
        timestamp: DateTime.now(),
      ));
    }

    setState(() {
      _activeChild = _children.first;
      _isInitialized = true;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Guardar mensaje del usuario
    await _storage.insertMessage(userMessage);

    // Simular respuesta del asistente (Fase 0: respuestas predefinidas)
    await Future.delayed(const Duration(milliseconds: 1200));

    final respuesta = _generarRespuestaDemo(text);

    final assistantMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'assistant',
      content: respuesta,
      timestamp: DateTime.now(),
    );

    // Extraer y procesar bloques <conducta>
    final conductaBlocks = ConductaParser.parseConductaBlocks(respuesta);
    if (conductaBlocks.isNotEmpty) {
      for (final block in conductaBlocks) {
        // Normalizar fecha
        block['fechaNormalizada'] = ConductaParser.normalizarFecha(
          block['fecha'] as String? ?? 'hoy',
          DateTime.now(),
        );
        // Asignar childId del perfil activo
        block['childId'] = _activeChild?.childId;
      }
    }

    // Limpiar respuesta para mostrar al usuario (quitar bloques <conducta>)
    final cleanResponse =
        ConductaParser.stripConductaBlocks(respuesta);

    final displayMessage = assistantMessage.copyWith(content: cleanResponse);

    setState(() {
      _messages.add(displayMessage);
      _isLoading = false;
    });

    await _storage.insertMessage(displayMessage);
    _scrollToBottom();
  }

  String _generarRespuestaDemo(String userMessage) {
    final msg = userMessage.toLowerCase();

    if (msg.contains('crisis') || msg.contains('berrinche') || msg.contains('grit') || msg.contains('tir')) {
      return 'Entiendo que debe haber sido un momento muy difícil. Has hecho bien en mantener la calma. '
          '¿Podemos hablar de lo que pasó antes de la crisis? A veces identificar el desencadenante nos ayuda a prevenirlo la próxima vez.\n\n'
          '<conducta>\n'
          '{\n'
          '  "fecha": "hoy",\n'
          '  "tipo": "crisis",\n'
          '  "descripcion": "Episodio de desregulación reportado por el cuidador",\n'
          '  "intensidad": "4",\n'
          '  "contexto": "hogar"\n'
          '}\n'
          '</conducta>';
    }

    if (msg.contains('sueño') || msg.contains('dormir') || msg.contains('despierta') || msg.contains('noche')) {
      return 'Las dificultades con el sueño son muy comunes en niños TEA. La falta de rutinas consistentes '
          'y la hipersensibilidad sensorial pueden influir mucho. ¿Has probado con un ritual visual antes de dormir?\n\n'
          '<conducta>\n'
          '{\n'
          '  "fecha": "hoy",\n'
          '  "tipo": "problema_sueño",\n'
          '  "descripcion": "Alteración del sueño reportada por el cuidador",\n'
          '  "intensidad": "3",\n'
          '  "contexto": "hogar, noche"\n'
          '}\n'
          '</conducta>';
    }

    if (msg.contains('comer') || msg.contains('comida') || msg.contains('alimento') || msg.contains('textura')) {
      return 'La selectividad alimentaria es un desafío frecuente. Es importante no presionar y ofrecer los '
          'alimentos nuevos junto a los conocidos. ¿Cuál es su comida favorita actualmente?\n\n'
          '<conducta>\n'
          '{\n'
          '  "fecha": "hoy",\n'
          '  "tipo": "rechazo_alimentario",\n'
          '  "descripcion": "Selectividad alimentaria durante la comida",\n'
          '  "intensidad": "2",\n'
          '  "contexto": "hogar, hora de comida"\n'
          '}\n'
          '</conducta>';
    }

    if (msg.contains('logro') || msg.contains('dijo') || msg.contains('habló') || msg.contains('comunic') || msg.contains('palabra')) {
      return '¡Qué maravilla! Cada pequeño logro comunicativo es un paso enorme. Es importante celebrarlo '
          'y reforzarlo positivamente. ¿Cómo reaccionaste cuando pasó? Me encantaría que lo registremos juntos.\n\n'
          '<conducta>\n'
          '{\n'
          '  "fecha": "hoy",\n'
          '  "tipo": "logro_comunicativo",\n'
          '  "descripcion": "Nuevo logro comunicativo reportado por el cuidador",\n'
          '  "intensidad": "5",\n'
          '  "contexto": "hogar"\n'
          '}\n'
          '</conducta>';
    }

    if (msg.contains('colegio') || msg.contains('escuela') || msg.contains('cole') || msg.contains('profe')) {
      return 'La comunicación con el colegio es fundamental. ¿Has podido hablar con su tutor/a esta semana? '
          'Recuerda que la bitácora que vamos construyendo puede ser una herramienta muy valiosa para compartir '
          'con el equipo educativo.';

    }

    if (msg.contains('gracias') || msg.contains('ayuda')) {
      return 'Para eso estoy aquí, para acompañarte en este camino. Recuerda que cuidar de ti también es parte '
          'del cuidado de ${_activeChild?.name ?? "tu hijo"}. ¿Y tú cómo estás hoy?';
    }

    if (msg.contains('cansad') || msg.contains('agotad') || msg.contains('frustrad') || msg.contains('estrés')) {
      return 'Es totalmente válido sentirse así. Cuidar a un niño con TEA requiere una energía inmensa, y a menudo '
          'nos olvidamos de nosotros mismos. Respira hondo. No estás solo/a en esto. '
          '¿Hay algo pequeño que pueda hacer hoy para ayudarte a sentirte mejor?';
    }

    // Respuesta por defecto
    if (_messages.length <= 2) {
      return 'Cuéntame más sobre cómo va todo. Estoy aquí para escucharte, sin prisas. '
          '¿Hay algo específico que te preocupe o quieras compartir sobre ${_activeChild?.name ?? "tu hijo"}?';
    }

    return 'Entiendo. Gracias por compartirlo conmigo. ¿Quieres que profundicemos en algún tema en particular? '
        'Puedo ayudarte con estrategias para crisis, sueño, alimentación, comunicación, o simplemente '
        'puedes contarme cómo te sientes hoy.';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('TEAcompáñame'),
            const SizedBox(width: 8),
            if (_activeChild != null)
              ChildSelector(
                children: _children,
                activeChild: _activeChild!,
                onChanged: (child) {
                  setState(() {
                    _activeChild = child;
                  });
                },
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Acerca de TEAcompáñame'),
                  content: Text(
                    'Asistente virtual empático para padres y cuidadores de niños con TEA.\n\n'
                    'Perfil activo: ${_activeChild?.name ?? "—"}\n'
                    'Edad: ${_activeChild?.age ?? 0} años\n'
                    'Diagnóstico: ${_activeChild?.diagnosis ?? "—"}\n\n'
                    'Los registros de conducta se guardan localmente en el dispositivo.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de perfil activo
          if (_activeChild != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppTheme.primaryGreen.withOpacity(0.08),
              child: Row(
                children: [
                  Text(
                    _activeChild!.avatar ?? '👤',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hablando sobre ${_activeChild!.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return const ChatBubble(
                    message: '',
                    isUser: false,
                    timestamp: null,
                    isTyping: true,
                  );
                }
                final message = _messages[index];
                return ChatBubble(
                  message: message.content,
                  isUser: message.role == 'user',
                  timestamp: message.timestamp,
                );
              },
            ),
          ),

          // Barra de entrada de texto
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _isLoading ? null : _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
