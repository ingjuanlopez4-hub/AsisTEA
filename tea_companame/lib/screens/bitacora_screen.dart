import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/conducta_record.dart';
import '../services/storage_service.dart';

class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});

  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  final StorageService _storage = StorageService();
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
    setState(() {
      _records = records;
      _isLoading = false;
    });
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
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState()
              : _buildRecordsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddManualDialog,
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
              'Los registros de conducta aparecerán aquí\na medida que converses con TEAcompáñame.',
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
                _buildDetailRow('Intensidad', _intensidadLabel(record.intensidad)),
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
                    Icon(
                      record.confirmado
                          ? Icons.verified
                          : Icons.access_time,
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

  void _showAddManualDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir registro manual'),
        content: const Text(
          'Funcionalidad disponible en la próxima versión.\n\n'
          'Por ahora, puedes generar registros conversando con TEAcompáñame en la pantalla de Chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
