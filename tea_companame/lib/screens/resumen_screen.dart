import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/conducta_record.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';

class ResumenScreen extends StatefulWidget {
  const ResumenScreen({super.key});

  @override
  State<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  final StorageService _storage = StorageService();
  bool _isLoading = true;

  // Métricas calculadas
  int _totalRecords = 0;
  int _crisisThisWeek = 0;
  int _logrosThisMonth = 0;
  List<Map<String, dynamic>> _crisisByWeek = [];
  List<MapEntry<String, int>> _topTriggers = [];
  List<ConductaRecord> _recentLogros = [];
  int _confirmedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    try {
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
      final monthStart = DateTime(now.year, now.month, 1);

      final allRecords = await _storage.getConductaRecords();
      if (!mounted) return;

      // Totales
      _totalRecords = allRecords.length;
      _confirmedCount = allRecords.where((r) => r.confirmado).length;

      // Crisis esta semana
      final thisWeek = allRecords.where((r) =>
          r.tipo == 'crisis' &&
          !r.createdAt.isBefore(weekStart) &&
          !r.createdAt.isAfter(now));
      _crisisThisWeek = thisWeek.length;

      // Logros este mes
      final logrosThisMonth = allRecords.where((r) =>
          (r.tipo == 'logro_comunicativo' || r.tipo == 'logro_social' || r.tipo == 'avance_motor' || r.tipo == 'autorregulación') &&
          !r.createdAt.isBefore(monthStart) &&
          !r.createdAt.isAfter(now));
      _logrosThisMonth = logrosThisMonth.length;

      // Crisis por semana (últimas 6)
      _crisisByWeek = await _storage.getCrisisByWeek(weeks: 6);

      // Top desencadenantes
      _topTriggers = await _storage.getTopTriggers(limit: 8);

      // Logros recientes (últimos 5)
      final logros = allRecords.where((r) =>
          r.tipo == 'logro_comunicativo' ||
          r.tipo == 'logro_social' ||
          r.tipo == 'avance_motor' ||
          r.tipo == 'autorregulación');
      _recentLogros = logros.take(5).toList();
    } catch (e) {
      debugPrint('[ResumenScreen] Error loading metrics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar métricas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadMetrics();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMetrics,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Header: 3 metric cards ===
          _buildMetricRow(),
          const SizedBox(height: 24),

          // === Crisis por semana ===
          _buildSectionHeader('Crisis por semana', Icons.bar_chart_rounded),
          const SizedBox(height: 8),
          _buildCrisisChart(),
          const SizedBox(height: 24),

          // === Desencadenantes más frecuentes ===
          if (_topTriggers.isNotEmpty) ...[
            _buildSectionHeader(
                'Desencadenantes frecuentes', Icons.sensors_outlined),
            const SizedBox(height: 8),
            _buildTriggersList(),
            const SizedBox(height: 24),
          ],

          // === Logros recientes ===
          _buildSectionHeader('Logros recientes', Icons.emoji_events_outlined),
          const SizedBox(height: 8),
          _recentLogros.isEmpty ? _buildEmptyLogros() : _buildLogrosList(),
          const SizedBox(height: 24),

          // === Botón de informe ===
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onGenerateReport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generar informe para terapeuta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Metric Row
  // ─────────────────────────────────────────────

  Widget _buildMetricRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.assignment_rounded,
            label: 'Registros',
            value: '$_totalRecords',
            subtitle: '$_confirmedCount confirmados',
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.warning_amber_rounded,
            label: 'Crisis',
            value: '$_crisisThisWeek',
            subtitle: 'esta semana',
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.emoji_events_rounded,
            label: 'Logros',
            value: '$_logrosThisMonth',
            subtitle: 'este mes',
            color: Colors.amber.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Crisis Chart (using built-in widgets)
  // ─────────────────────────────────────────────

  Widget _buildCrisisChart() {
    final maxCount = _crisisByWeek.fold<int>(
      0,
      (max, w) => (w['count'] as int) > max ? w['count'] as int : max,
    );
    final effectiveMax = maxCount < 3 ? 3 : maxCount; // min bar height

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Últimas 6 semanas',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_crisisByWeek.length, (i) {
                  final week = _crisisByWeek[i];
                  final count = week['count'] as int;
                  final ratio = count / effectiveMax;
                  final barHeight = ratio * 120;
                  final isCurrentWeek = i == _crisisByWeek.length - 1;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Count label above bar
                          if (count > 0)
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isCurrentWeek
                                    ? AppTheme.primaryGreen
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          // Bar
                          Container(
                            width: double.infinity,
                            height: barHeight.clamp(4.0, 120.0),
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(6)),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: isCurrentWeek
                                    ? [AppTheme.primaryGreen, AppTheme.primaryGreenLight]
                                    : [
                                        Colors.orange.withOpacity(0.4),
                                        Colors.orange.withOpacity(0.2),
                                      ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Week label
                          Text(
                            week['weekLabel'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (_crisisByWeek.every((w) => (w['count'] as int) == 0))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Sin crisis registradas en las últimas 6 semanas',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Triggers list
  // ─────────────────────────────────────────────

  Widget _buildTriggersList() {
    final maxFreq = _topTriggers.isNotEmpty ? _topTriggers.first.value : 1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(_topTriggers.length, (i) {
            final entry = _topTriggers[i];
            final ratio = entry.value / maxFreq;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _capitalize(entry.key),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _triggerColor(i),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Color _triggerColor(int index) {
    final colors = [
      AppTheme.accentWarm,
      AppTheme.primaryGreen,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  // ─────────────────────────────────────────────
  // Logros section
  // ─────────────────────────────────────────────

  Widget _buildEmptyLogros() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 36,
              color: Colors.amber.withOpacity(0.4),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Aún no hay logros registrados. '
                'Los progresos comunicativos y sociales aparecerán aquí.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogrosList() {
    return Column(
      children: List.generate(_recentLogros.length, (i) {
        final logro = _recentLogros[i];
        final tipoLabel = _tipoLogroLabel(logro.tipo);
        final icon = _tipoLogroIcon(logro.tipo);
        final color = _tipoLogroColor(logro.tipo);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(
              tipoLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              logro.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              _formatDate(logro.fechaNormalizada),
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }

  String _tipoLogroLabel(String tipo) {
    switch (tipo) {
      case 'logro_comunicativo':
        return 'Comunicación';
      case 'logro_social':
        return 'Social';
      case 'avance_motor':
        return 'Motor';
      case 'autorregulación':
        return 'Autorregulación';
      default:
        return tipo.replaceAll('_', ' ');
    }
  }

  IconData _tipoLogroIcon(String tipo) {
    switch (tipo) {
      case 'logro_comunicativo':
        return Icons.forum;
      case 'logro_social':
        return Icons.people;
      case 'avance_motor':
        return Icons.directions_walk;
      case 'autorregulación':
        return Icons.self_improvement;
      default:
        return Icons.star;
    }
  }

  Color _tipoLogroColor(String tipo) {
    switch (tipo) {
      case 'logro_comunicativo':
        return Colors.green;
      case 'logro_social':
        return Colors.teal;
      case 'avance_motor':
        return Colors.lightGreen;
      case 'autorregulación':
        return Colors.cyan;
      default:
        return Colors.amber;
    }
  }

  // ─────────────────────────────────────────────
  // Informe
  // ─────────────────────────────────────────────

  void _onGenerateReport() async {
    try {
      // Obtener datos para el informe
      final records = await _storage.getConductaRecords();
      final trigers = await _storage.getTopTriggers(limit: 5);
      final crisisByType = await _storage.getRecordCountByType();

      if (!mounted) return;

      // Construir resumen del informe
      final crisisCount = crisisByType['crisis'] ?? 0;
      final logrosCount = (crisisByType['logro_comunicativo'] ?? 0) +
          (crisisByType['logro_social'] ?? 0) +
          (crisisByType['avance_motor'] ?? 0) +
          (crisisByType['autorregulación'] ?? 0);
      final sleepIssues = crisisByType['problema_sueño'] ?? 0;
      final foodIssues = crisisByType['rechazo_alimentario'] ?? 0;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.description_outlined, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              const Text('Informe de Bitácora'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Generado: ${_formatDate(DateTime.now())}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Resumen General',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(),
                _reportRow('Total registros', '${records.length}'),
                _reportRow('Crisis registradas', '$crisisCount'),
                _reportRow('Logros', '$logrosCount'),
                _reportRow('Problemas de sueño', '$sleepIssues'),
                _reportRow('Rechazo alimentario', '$foodIssues'),
                const SizedBox(height: 12),
                if (trigers.isNotEmpty) ...[
                  const Text(
                    'Desencadenantes frecuentes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(),
                  ...trigers.map((t) => _reportRow(
                        _capitalize(t.key),
                        '${t.value} veces',
                      )),
                ],
                const SizedBox(height: 16),
                Text(
                  'Este informe se puede compartir con terapeutas y profesionales de la salud.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showExportOptions();
              },
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Exportar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar informe: $e')),
        );
      }
    }
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() async {
    try {
      final records = await _storage.getConductaRecords();
      if (!mounted || records.isEmpty) return;

      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exportar informe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona el formato para exportar el informe:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    const Icon(Icons.data_object, color: AppTheme.primaryGreen),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Generando archivo...'),
            ],
          ),
          duration: Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ),
      );

      String path;
      if (result == 'json') {
        path = await exportService.exportToJson(records);
      } else {
        path = await exportService.exportToHtml(records);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showExportSuccess(path, result == 'json' ? 'JSON' : 'HTML');
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
              'Puedes encontrar el archivo en la carpeta indicada y compartirlo con quien necesites.',
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
  // Helpers
  // ─────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatDate(dynamic date) {
    DateTime d;
    if (date is DateTime) {
      d = date;
    } else if (date is String) {
      try {
        d = DateTime.parse(date);
      } catch (_) {
        return date;
      }
    } else {
      return '$date';
    }
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }
}
