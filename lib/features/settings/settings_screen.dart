import 'package:flutter/material.dart';
import '../../shared/services/app_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppSettingsService _settings = AppSettingsService();
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            leading: Navigator.canPop(context) ? IconButton(icon: Icon(Icons.arrow_back, color: colorScheme.onSurface), onPressed: () => Navigator.pop(context)) : null,
            title: Text('Settings', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [colorScheme.primary.withValues(alpha: 0.3), colorScheme.secondary.withValues(alpha: 0.3)]), border: Border.all(color: colorScheme.primary, width: 2)),
                    child: Stack(children: [
                      Center(child: Icon(Icons.person, color: colorScheme.primary, size: 40)),
                      Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 14))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  Text('Alex Johnson', style: TextStyle(color: colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('alex.j@pantrix.com', style: TextStyle(color: colorScheme.primary, fontSize: 14)),
                ]),
                const SizedBox(height: 32),
                _buildSectionHeader('APP PREFERENCES', colorScheme),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  colorScheme: colorScheme,
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  trailing: Switch(
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                    thumbColor: WidgetStateProperty.all(Colors.white),
                    trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? colorScheme.primary : null),
                  ),
                ),
                _buildSettingsTile(
                  colorScheme: colorScheme,
                  icon: Icons.access_time,
                  title: 'Expiry Alert Timing',
                  subtitle: '${_settings.expiryAlertDays} days before',
                  trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  onTap: () => _showExpiryTimingPicker(colorScheme),
                ),
                _buildSettingsTile(
                  colorScheme: colorScheme,
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: _settings.themeMode == ThemeMode.dark,
                    onChanged: (v) => _settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                    thumbColor: WidgetStateProperty.all(Colors.white),
                    trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? colorScheme.primary : null),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('REGION', colorScheme),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  colorScheme: colorScheme,
                  icon: Icons.location_on_outlined,
                  title: 'Selected Region',
                  subtitle: _settings.selectedRegion,
                  trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  onTap: () => _showRegionPicker(colorScheme),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('ACCOUNT', colorScheme),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  colorScheme: colorScheme,
                  icon: Icons.security_outlined,
                  title: 'Privacy & Security',
                  trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
                _buildSettingsTile(
                  colorScheme: colorScheme,
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: 'English (US)',
                  trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.5))),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout, color: Colors.red, size: 20), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600))]),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Zerospill Smart Food Management', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                Text('Version 1.0.0', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRegionPicker(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Region', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Recipes will be filtered based on your region', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _settings.availableRegions.length,
                itemBuilder: (context, index) {
                  final region = _settings.availableRegions[index];
                  final isSelected = _settings.selectedRegion == region;
                  return ListTile(
                    title: Text(region, style: TextStyle(color: isSelected ? colorScheme.primary : colorScheme.onSurface)),
                    trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
                    onTap: () {
                      _settings.setRegion(region);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Theme', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Choose your preferred theme mode', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
            const SizedBox(height: 16),
            _buildThemeOption(ThemeMode.light, 'Light', Icons.light_mode, colorScheme),
            _buildThemeOption(ThemeMode.dark, 'Dark', Icons.dark_mode, colorScheme),
            _buildThemeOption(ThemeMode.system, 'System', Icons.brightness_auto, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(ThemeMode mode, String label, IconData icon, ColorScheme colorScheme) {
    final isSelected = _settings.themeMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6)),
      title: Text(label, style: TextStyle(color: isSelected ? colorScheme.primary : colorScheme.onSurface)),
      trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
      onTap: () {
        _settings.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showExpiryTimingPicker(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expiry Alert Timing', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('When should we notify you about expiring items?', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
            const SizedBox(height: 16),
            _buildExpiryOption(1, colorScheme),
            _buildExpiryOption(3, colorScheme),
            _buildExpiryOption(7, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryOption(int days, ColorScheme colorScheme) {
    final isSelected = _settings.expiryAlertDays == days;
    return ListTile(
      title: Text('$days days before', style: TextStyle(color: isSelected ? colorScheme.primary : colorScheme.onSurface)),
      trailing: isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
      onTap: () {
        _settings.setExpiryAlertDays(days);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) => Align(alignment: Alignment.centerLeft, child: Text(title, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)));

  Widget _buildSettingsTile({required ColorScheme colorScheme, required IconData icon, required String title, String? subtitle, required Widget trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: colorScheme.primary, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)), if (subtitle != null) Text(subtitle, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12))])),
          trailing,
        ]),
      ),
    );
  }
}
