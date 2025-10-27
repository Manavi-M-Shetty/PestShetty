import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0E0A) : const Color(0xFFF8FBF8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green,
      ),
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
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
            ),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('Princita Liesha DSouza'),
            ),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('Rakshita R'),
            ),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('Reesha Jashal Lobo'),
            ),
            const Divider(),
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
            ),
            const Divider(),
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
            ),
          ],
        ),
      ),
    );
  }
}
