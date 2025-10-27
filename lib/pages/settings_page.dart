import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 2;

  void _onTabTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);

    final route = index == 0 ? '/' : (index == 1 ? '/detect' : '/settings');
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E0A) : const Color(0xFFF8FBF8);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green,
      ),
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Language / ಭಾಷೆ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SwitchListTile(
                title: Text(languageProvider.isKannada ? 'ಕನ್ನಡ' : 'English'),
                subtitle: Text(languageProvider.isKannada ? 'ಭಾಷೆ ಬದಲಾಯಿಸಲು ಸ್ವಿಚ್ ಮಾಡಿ' : 'Switch to change language'),
                value: languageProvider.isKannada,
                onChanged: (bool value) {
                  languageProvider.setLanguage(value);
                },
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Team Members',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const ListTile(
                leading: Icon(Icons.person),
                title: Text('Manavi M Shetty'),
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                dense: true,
              ),
              const ListTile(
                leading: Icon(Icons.person),
                title: Text('Princita Liesha DSouza'),
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                dense: true,
              ),
              const ListTile(
                leading: Icon(Icons.person),
                title: Text('Rakshita R'),
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                dense: true,
              ),
              const ListTile(
                leading: Icon(Icons.person),
                title: Text('Reesha Jashal Lobo'),
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                dense: true,
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'About App',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Plant Space'),
                subtitle: Text('Version 1.0.0'),
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                dense: true,
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Licenses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const ListTile(
                leading: Icon(Icons.copyright),
                title: Text('© 2025 Plant Space'),
                subtitle: Text('All rights reserved'),
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                dense: true,
              ),
              const SizedBox(height: 90), // Space for bottom navigation
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        indicatorColor: Colors.green.shade100,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: Colors.green),
            label: languageProvider.isKannada ? 'ಮುಖಪುಟ' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.camera_alt_outlined),
            selectedIcon: const Icon(Icons.camera_alt, color: Colors.green),
            label: languageProvider.isKannada ? 'ಪತ್ತೆ ಮಾಡಿ' : 'Detect',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: Colors.green),
            label: languageProvider.isKannada ? 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು' : 'Settings',
          ),
        ],
      ),
    );
  }
}