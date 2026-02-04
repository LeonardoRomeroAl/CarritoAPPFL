import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _kNotifs = 'settings_notifications_enabled';
  static const _kDarkMode = 'settings_dark_mode';

  bool _loading = true;
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_kNotifs) ?? true;
      _darkMode = prefs.getBool(_kDarkMode) ?? false;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifs, _notificationsEnabled);
    await prefs.setBool(_kDarkMode, _darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Notificaciones'),
                  subtitle: const Text('Recibir avisos de pedidos y facturas'),
                  value: _notificationsEnabled,
                  onChanged: (v) async {
                    setState(() {
                      _notificationsEnabled = v;
                    });
                    await _save();
                  },
                ),
                SwitchListTile(
                  title: const Text('Modo oscuro'),
                  subtitle: const Text('Idea: tema oscuro en toda la app'),
                  value: _darkMode,
                  onChanged: (v) async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() {
                      _darkMode = v;
                    });
                    await _save();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Pendiente: aplicar tema global.')),
                      );
                    }
                  },
                ),
                ListTile(
                  title: const Text('Privacidad y términos'),
                  subtitle: const Text('Idea: abrir URL con políticas'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    Navigator.pushNamed(context, '/terms');
                  },
                ),
                ListTile(
                  title: const Text('Conócenos'),
                  subtitle: const Text('Acerca de LF Comercializadora'),
                  trailing: const Icon(Icons.info_outline),
                  onTap: () {
                    Navigator.pushNamed(context, '/about');
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Borrar caché'),
                  subtitle: const Text('Idea: limpiar datos locales (direcciones, settings)'),
                  trailing: const Icon(Icons.delete_outline),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pendiente: acción de borrado selectivo.')),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
