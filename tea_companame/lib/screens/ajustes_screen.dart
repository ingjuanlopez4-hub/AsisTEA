import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/child_profile.dart';
import '../services/storage_service.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final StorageService _storage = StorageService();
  List<ChildProfile> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await _storage.getChildProfiles();
    setState(() {
      _children = profiles;
      _isLoading = false;
    });
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
