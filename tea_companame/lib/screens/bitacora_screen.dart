import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../config/theme.dart';
import '../models/conducta_record.dart';
import '../models/child_profile.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';

class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});

  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();
  List<ConductaRecord> _records = [];
  String? _selectedTipo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _storage.getConductaRecords();
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  List<ConductaRecord> get _filteredRecords {
    if (_selectedTipo == null) return _records;
    return _records.where((r) => r.tipo == _selectedTipo).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitácora'),
        actions: [
          if (_records.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Exportar bitácora',
              onPressed: _showExportOptions,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState()
              : _buildRecordsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddManualSheet,
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: AppTheme.primaryGreen.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Bitácora vacía',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Los registros de conducta aparecerán aquí\na medida que converses con TEAcompáñame.\n\nTambién puedes añadirlos manualmente\ntocando el botón +.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    final records = _filteredRecords;
    return Column(
      children: [
        if (_selectedTipo != null) _buildActiveFilter(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildRecordCard(record);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.accentWarm.withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18),
          const SizedBox(width: 8),
          Text(
            'Filtrando: $_selectedTipo',
            style: const TextStyle(fontSize: 13),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _selectedTipo = null),
            child: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(ConductaRecord record) {
    final tipoLabel = record.tipo.replaceAll('_', ' ');
    final tipoCapitalized =
        tipoLabel[0].toUpperCase() + tipoLabel.substring(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: _getTipoIcon(record.tipo),
        title: Text(
          tipoCapitalized,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          record.descripcion,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Fecha', record.fechaNormalizada),
                _buildDetailRow(
                    'Intensidad', _intensidadLabel(record.intensidad)),
                if (record.duracion.isNotEmpty)
                  _buildDetailRow('Duración', record.duracion),
                if (record.contexto.isNotEmpty)
                  _buildDetailRow('Contexto', record.contexto),
                if (record.desencadenantes.isNotEmpty)
                  _buildDetailRow(
                    'Desencadenantes',
                    record.desencadenantes.join(', '),
                  ),
                if (record.estrategiasAplicadas.isNotEmpty)
                  _buildDetailRow('Estrategias', record.estrategiasAplicadas),
                if (record.resultado.isNotEmpty)
                  _buildDetailRow('Resultado', record.resultado),
                if (record.notas != null && record.notas!.isNotEmpty)
                  _buildDetailRow('Notas', record.notas!),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Confirmar (solo si no está confirmado)
                    if (!record.confirmado)
                      TextButton.icon(
                        onPressed: () {
                          final updated = ConductaRecord(
                            recordId: record.recordId,
                            childId: record.childId,
                            userId: record.userId,
                            source: record.source,
                            conversationId: record.conversationId,
                            fecha: record.fecha,
                            fechaNormalizada: record.fechaNormalizada,
                            tipo: record.tipo,
                            descripcion: record.descripcion,
                            intensidad: record.intensidad,
                            duracion: record.duracion,
                            desencadenantes: record.desencadenantes,
                            contexto: record.contexto,
                            estrategiasAplicadas: record.estrategiasAplicadas,
                            resultado: record.resultado,
                            notas: record.notas,
                            confirmado: true,
                            createdAt: record.createdAt,
                          );
                          _storage.updateConductaRecord(updated);
                          _loadRecords();
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirmar'),
                      ),
                    const Spacer(),
                    // Eliminar
                    IconButton(
                      onPressed: () => _confirmDelete(record),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.redAccent.withOpacity(0.7),
                      tooltip: 'Eliminar registro',
                    ),
                    const SizedBox(width: 4),
                    // Estado
                    Icon(
                      record.confirmado ? Icons.verified : Icons.access_time,
                      size: 18,
                      color: record.confirmado
                          ? AppTheme.primaryGreen
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record.confirmado ? 'Confirmado' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 12,
                        color: record.confirmado
                            ? AppTheme.primaryGreen
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _intensidadLabel(String intensidad) {
    switch (intensidad) {
      case '1':
        return '1 - Leve';
      case '2':
        return '2 - Moderado';
      case '3':
        return '3 - Notable';
      case '4':
        return '4 - Intenso';
      case '5':
        return '5 - Severo';
      default:
        return 'No especificada';
    }
  }

  Widget _getTipoIcon(String tipo) {
    IconData icon;
    Color color;

    switch (tipo) {
      case 'crisis':
        icon = Icons.warning_amber_rounded;
        color = Colors.redAccent;
        break;
      case 'estereotipia':
        icon = Icons.repeat;
        color = Colors.orange;
        break;
      case 'rechazo_alimentario':
        icon = Icons.restaurant;
        color = Colors.amber;
        break;
      case 'problema_sueño':
        icon = Icons.nightlight_round;
        color = Colors.indigo;
        break;
      case 'logro_comunicativo':
        icon = Icons.forum;
        color = Colors.green;
        break;
      case 'logro_social':
        icon = Icons.people;
        color = Colors.teal;
        break;
      case 'desencadenante_sensorial':
        icon = Icons.sensors;
        color = Colors.purple;
        break;
      case 'avance_motor':
        icon = Icons.directions_walk;
        color = Colors.lightGreen;
        break;
      case 'rigidez_cognitiva':
        icon = Icons.lock_outline;
        color = Colors.brown;
        break;
      case 'interés_restringido':
        icon = Icons.star;
        color = Colors.yellow.shade700;
        break;
      case 'ansiedad_separación':
        icon = Icons.sentiment_dissatisfied;
        color = Colors.blueGrey;
        break;
      case 'autorregulación':
        icon = Icons.self_improvement;
        color = Colors.cyan;
        break;
      default:
        icon = Icons.notes;
        color = Colors.grey;
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withOpacity(0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrar por tipo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ConductaRecord.tiposValidos.map((tipo) {
                  final isSelected = _selectedTipo == tipo;
                  return FilterChip(
                    label: Text(tipo.replaceAll('_', ' ')),
                    selected: isSelected,
                    onSelected: (selected) {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedTipo = selected ? tipo : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Exportación
  // ─────────────────────────────────────────────

  Future<void> _showExportOptions() async {
    if (_records.isEmpty) return;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar bitácora'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el formato para exportar los registros:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.data_object, color: AppTheme.primaryGreen),
              title: const Text('JSON'),
              subtitle: const Text('Datos estructurados para análisis'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () => Navigator.pop(ctx, 'json'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.web, color: Colors.blue),
              title: const Text('HTML'),
              subtitle: const Text('Informe visual para terapeuta'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () => Navigator.pop(ctx, 'html'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    final exportService = ExportService();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Generando archivo...'),
            ],
          ),
          duration: Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (result == 'json') {
        final path = await exportService.exportToJson(_records);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showExportSuccess(path, 'JSON');
        }
      } else {
        final path = await exportService.exportToHtml(_records);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showExportSuccess(path, 'HTML');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al exportar: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showExportSuccess(String filePath, String format) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              format == 'JSON' ? Icons.data_object : Icons.web,
              color: AppTheme.primaryGreen,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text('Exportado como $format'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Archivo generado correctamente.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filePath,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Puedes encontrar el archivo en la carpeta indicada y compartirlo con quien necesites.\n\n📱 En Android: Abre la app "Archivos" > Almacenamiento interno > Android > data > com.example.tea_companame > cache > teacompaname_exports\n\n💻 Abre el archivo HTML en el navegador para imprimirlo como PDF.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Eliminar registro
  // ─────────────────────────────────────────────

  Future<void> _confirmDelete(ConductaRecord record) async {

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Estás segura de eliminar este registro de tipo "${record.tipo.replaceAll('_', ' ')}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _storage.deleteConductaRecord(record.recordId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🗑️ Registro eliminado'),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadRecords();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al eliminar: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // ─────────────────────────────────────────────
  // Registro manual de conducta
  // ─────────────────────────────────────────────

  void _showAddManualSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _ManualConductaForm(),
    ).then((_) => _loadRecords());
  }
}

// ================================================================
// Formulario de registro manual
// ================================================================

class _ManualConductaForm extends StatefulWidget {
  const _ManualConductaForm();

  @override
  State<_ManualConductaForm> createState() => _ManualConductaFormState();
}

class _ManualConductaFormState extends State<_ManualConductaForm> {
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController();
  final _contextoCtrl = TextEditingController();
  final _estrategiasCtrl = TextEditingController();
  final _resultadoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  String _selectedTipo = 'crisis';
  DateTime _selectedDate = DateTime.now();
  double _intensidad = 3;
  bool _isSaving = false;

  // Tags para desencadenantes
  final _triggerCtrl = TextEditingController();
  final List<String> _triggers = [];
  final _triggerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _duracionCtrl.dispose();
    _contextoCtrl.dispose();
    _estrategiasCtrl.dispose();
    _resultadoCtrl.dispose();
    _notasCtrl.dispose();
    _triggerCtrl.dispose();
    _triggerFocus.dispose();
    super.dispose();
  }

  void _addTrigger() {
    final text = _triggerCtrl.text.trim();
    if (text.isNotEmpty && !_triggers.contains(text)) {
      setState(() {
        _triggers.add(text);
        _triggerCtrl.clear();
      });
      _triggerFocus.requestFocus();
    }
  }

  void _removeTrigger(String trigger) {
    setState(() => _triggers.remove(trigger));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime d) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _toIsoDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final children = await _storage.getChildProfiles();
      final childId = children.isNotEmpty ? children.first.childId : 'default';
      final recordId = _uuid.v4();
      final now = DateTime.now();

      final record = ConductaRecord(
        recordId: recordId,
        childId: childId,
        userId: 'user_1',
        source: 'manual',
        fecha: _toIsoDate(_selectedDate),
        fechaNormalizada: _toIsoDate(_selectedDate),
        tipo: _selectedTipo,
        descripcion: _descripcionCtrl.text.trim(),
        intensidad: _intensidad.round().toString(),
        duracion: _duracionCtrl.text.trim(),
        desencadenantes: List.from(_triggers),
        contexto: _contextoCtrl.text.trim(),
        estrategiasAplicadas: _estrategiasCtrl.text.trim(),
        resultado: _resultadoCtrl.text.trim(),
        notas: _notasCtrl.text.trim().isNotEmpty
            ? _notasCtrl.text.trim()
            : null,
        confirmado: true,
        createdAt: now,
      );

      await _storage.insertConductaRecord(record);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Registro guardado en la bitácora'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded,
                          color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Nuevo registro de conducta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Form body
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      // Tipo
                      _buildFieldLabel('Tipo de conducta *'),
                      const SizedBox(height: 6),
                      _buildTipoSelector(),
                      const SizedBox(height: 16),

                      // Fecha
                      _buildFieldLabel('Fecha'),
                      const SizedBox(height: 6),
                      _buildDatePicker(),
                      const SizedBox(height: 16),

                      // Descripción
                      _buildFieldLabel('Descripción *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descripcionCtrl,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          hintText:
                              'Describe brevemente lo que ocurrió...',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().length < 3)
                                ? 'Describe el evento (mín. 3 caracteres)'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Intensidad
                      _buildFieldLabel('Intensidad'),
                      const SizedBox(height: 6),
                      _buildIntensidadSlider(),
                      const SizedBox(height: 16),

                      // Duración
                      _buildFieldLabel('Duración'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _duracionCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Ej: 15 minutos, toda la noche...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Desencadenantes (tags)
                      _buildFieldLabel('Desencadenantes'),
                      const SizedBox(height: 6),
                      _buildTriggersInput(),
                      const SizedBox(height: 16),

                      // Contexto
                      _buildFieldLabel('Contexto'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _contextoCtrl,
                        decoration: const InputDecoration(
                          hintText:
                              '¿Dónde ocurrió? ¿A qué hora? ¿Qué actividad?',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Estrategias aplicadas
                      _buildFieldLabel('Estrategias aplicadas'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _estrategiasCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: '¿Qué hiciste para manejar la situación?',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Resultado
                      _buildFieldLabel('Resultado'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _resultadoCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: '¿Cómo terminó? ¿Qué funcionó?',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notas
                      _buildFieldLabel('Notas adicionales'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notasCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Observaciones, ideas para el futuro...',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón guardar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                              _isSaving ? 'Guardando...' : 'Guardar registro'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Sub-widgets del formulario
  // ─────────────────────────────────────────────

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTipoSelector() {
    // Mostrar tipos en 2 filas de chips
    final tipos = ConductaRecord.tiposValidos;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tipos.map((tipo) {
        final isSelected = _selectedTipo == tipo;
        final label = tipo.replaceAll('_', ' ');
        final capitalizado =
            label[0].toUpperCase() + label.substring(1);

        return ChoiceChip(
          label: Text(
            capitalizado,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : null,
            ),
          ),
          selected: isSelected,
          selectedColor: _chipColor(tipo),
          onSelected: (selected) {
            if (selected) setState(() => _selectedTipo = tipo);
          },
        );
      }).toList(),
    );
  }

  Color _chipColor(String tipo) {
    switch (tipo) {
      case 'crisis':
        return Colors.redAccent;
      case 'estereotipia':
        return Colors.orange;
      case 'rechazo_alimentario':
        return Colors.amber;
      case 'problema_sueño':
        return Colors.indigo;
      case 'logro_comunicativo':
        return Colors.green;
      case 'logro_social':
        return Colors.teal;
      case 'desencadenante_sensorial':
        return Colors.purple;
      case 'avance_motor':
        return Colors.lightGreen;
      case 'rigidez_cognitiva':
        return Colors.brown;
      case 'interés_restringido':
        return Colors.amber.shade700;
      case 'ansiedad_separación':
        return Colors.blueGrey;
      case 'autorregulación':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
        ),
        child: Text(
          _formatDate(_selectedDate),
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildIntensidadSlider() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const Text('Baja', style: TextStyle(fontSize: 11)),
            Expanded(
              child: Slider(
                value: _intensidad,
                min: 1,
                max: 5,
                divisions: 4,
                label: _intensidad.round().toString(),
                activeColor: _intensidadColor(_intensidad.round()),
                onChanged: (v) => setState(() => _intensidad = v),
              ),
            ),
            const Text('Alta', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _intensidadColor(_intensidad.round()).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${_intensidad.round()}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _intensidadColor(_intensidad.round()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _intensidadColor(int value) {
    switch (value) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTriggersInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags existentes
        if (_triggers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _triggers.map((t) {
                return Chip(
                  label: Text(t, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeTrigger(t),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
        // Input + Add button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _triggerCtrl,
                focusNode: _triggerFocus,
                decoration: InputDecoration(
                  hintText: _triggers.isEmpty
                      ? 'Ej: ruido fuerte, transición...'
                      : 'Añadir otro...',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _addTrigger(),
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addTrigger,
              icon: const Icon(Icons.add, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.accentWarm,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
