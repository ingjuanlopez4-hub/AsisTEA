import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/child_profile.dart';
import '../models/api_config.dart';
import '../services/storage_service.dart';
import '../services/llm_service.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final StorageService _storage = StorageService();
  List<ChildProfile> _children = [];
  ApiConfig _apiConfig = const ApiConfig();
  bool _isLoading = true;
  bool _llmConnected = false;
  bool _checkingLlm = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profiles = await _storage.getChildProfiles();
    final config = await _storage.getApiConfig();
    setState(() {
      _children = profiles;
      _apiConfig = config;
      _isLoading = false;
    });
    _checkLlmConnection();
  }

  Future<void> _checkLlmConnection() async {
    setState(() => _checkingLlm = true);
    final service = LLMService(config: _apiConfig);
    final ok = await service.checkHealth();
    setState(() {
      _llmConnected = ok;
      _checkingLlm = false;
    });
  }

  Future<void> _showLlmConfigDialog() async {
    final baseUrlController =
        TextEditingController(text: _apiConfig.baseUrl);
    final modelController =
        TextEditingController(text: _apiConfig.model);
    final apiKeyController =
        TextEditingController(text: _apiConfig.apiKey);
    double temperature = _apiConfig.temperature;
    int maxTokens = _apiConfig.maxTokens;
    String mode = _apiConfig.mode;

    final result = await showDialog<ApiConfig>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Configurar LLM'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configura el servidor de IA local o remoto.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Modo
                    const Text('Modo',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'local', label: Text('Local')),
                        ButtonSegment(value: 'cloud', label: Text('Cloud')),
                      ],
                      selected: {mode},
                      onSelectionChanged: (v) {
                        setDialogState(() => mode = v.first);
                      },
                    ),
                    const SizedBox(height: 16),

                    // URL Base
                    TextField(
                      controller: baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Base',
                        hintText: 'http://localhost:11434/v1',
                        helperText: 'Ej: http://localhost:11434/v1 (Ollama)',
                        helperMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Modelo
                    TextField(
                      controller: modelController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                        hintText: 'llama3.2',
                        helperText: 'Ej: llama3.2, phi3, gpt-4o-mini',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // API Key (solo visible en modo cloud)
                    if (mode == 'cloud')
                      TextField(
                        controller: apiKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'API Key',
                          hintText: 'sk-...',
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Temperatura
                    Row(
                      children: [
                        const Text('Temperatura: ',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Expanded(
                          child: Slider(
                            value: temperature,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: temperature.toStringAsFixed(1),
                            onChanged: (v) {
                              setDialogState(() => temperature = v);
                            },
                          ),
                        ),
                        Text(temperature.toStringAsFixed(1)),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Max tokens
                    Row(
                      children: [
                        const Text('Max tokens: ',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Expanded(
                          child: Slider(
                            value: maxTokens.toDouble(),
                            min: 100,
                            max: 4000,
                            divisions: 39,
                            label: maxTokens.toString(),
                            onChanged: (v) {
                              setDialogState(() => maxTokens = v.round());
                            },
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(maxTokens.toString()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Botón de probar conexión
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.wifi_tethering, size: 18),
                        label: const Text('Probar conexión'),
                        onPressed: () async {
                          final testConfig = ApiConfig(
                            baseUrl: baseUrlController.text.trim(),
                            model: modelController.text.trim(),
                            apiKey: apiKeyController.text.trim(),
                            temperature: temperature,
                            maxTokens: maxTokens,
                            mode: mode,
                          );
                          final service = LLMService(config: testConfig);
                          final ok = await service.checkHealth();
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? '✅ Conexión exitosa con ${testConfig.model}'
                                    : '❌ No se pudo conectar. Verifica la URL y que el servidor esté corriendo.'),
                                backgroundColor:
                                    ok ? AppTheme.primaryGreen : Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final config = ApiConfig(
                      baseUrl: baseUrlController.text.trim(),
                      model: modelController.text.trim(),
                      apiKey: apiKeyController.text.trim(),
                      temperature: temperature,
                      maxTokens: maxTokens,
                      mode: mode,
                    );
                    Navigator.pop(ctx, config);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _storage.saveApiConfig(result);
      setState(() => _apiConfig = result);
      _checkLlmConnection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuración LLM guardada.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Sección: Perfiles de hijos
                _buildSectionHeader('Perfiles de hijos'),
                ..._children.map(
                  (child) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        child: Text(
                          child.avatar ?? '👤',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      title: Text(
                        child.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${child.age} años • ${child.diagnosis}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Editar perfil (próxima versión)
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sección: LLM (Asistente IA)
                _buildSectionHeader('Asistente IA (LLM)'),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          _llmConnected
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: _llmConnected
                              ? AppTheme.primaryGreen
                              : Colors.orange,
                        ),
                        title: const Text('Servidor LLM'),
                        subtitle: Text(
                          _checkingLlm
                              ? 'Verificando conexión...'
                              : (_llmConnected
                                  ? 'Conectado a ${_apiConfig.model}'
                                  : 'No conectado — usando modo demo'),
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: _checkingLlm
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _showLlmConfigDialog,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.dns_outlined),
                        title: const Text('URL Base'),
                        subtitle: Text(
                          _apiConfig.baseUrl,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: _showLlmConfigDialog,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.smart_toy_outlined),
                        title: const Text('Modelo'),
                        subtitle: Text(
                          _apiConfig.model,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: _showLlmConfigDialog,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sección: Preferencias
                _buildSectionHeader('Preferencias'),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Tema oscuro'),
                        subtitle: const Text(
                          'Reduce la fatiga visual nocturna',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: isDark,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (value) {
                          // Cambiar tema (se manejará desde app.dart)
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: const Text('Idioma'),
                        subtitle: const Text('Español'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        title: const Text('Notificaciones'),
                        subtitle: const Text(
                          'Recordatorios y resúmenes',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: true,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sección: Datos y Privacidad
                _buildSectionHeader('Privacidad y Datos'),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.download_rounded),
                        title: const Text('Exportar datos'),
                        subtitle: const Text(
                          'JSON / PDF / CSV',
                          style: TextStyle(fontSize: 13),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Exportación disponible en la próxima versión.',
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        title: const Text('Borrar todos los datos'),
                        subtitle: const Text(
                          'Esta acción no se puede deshacer',
                          style: TextStyle(fontSize: 13, color: Colors.redAccent),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('¿Borrar todos los datos?'),
                              content: const Text(
                                'Se eliminarán todos los registros de conducta, '
                                'conversaciones y perfiles. Esta acción no se puede deshacer.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Borrar datos (implementar)
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Datos borrados.'),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                  ),
                                  child: const Text('Borrar todo'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sección: Acerca de
                _buildSectionHeader('Acerca de'),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Versión'),
                        trailing: Text('1.0.0'),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.favorite_outline),
                        title: const Text('TEAcompáñame'),
                        subtitle: const Text(
                          'Asistente virtual para familias TEA',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }
}
