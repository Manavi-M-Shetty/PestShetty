import 'package:flutter/material.dart';

/// Minimal ActionCard used by HomePage.
/// Accepts an [onPressed] callback to match existing usage.
class ActionCard extends StatelessWidget {
  final VoidCallback? onPressed;
  const ActionCard({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: const Text('Quick Actions'),
        subtitle: const Text('Detect pests, add crops, or view history'),
        trailing: ElevatedButton(
          onPressed: onPressed,
          child: const Text('Detect'),
        ),
      ),
    );
  }
}
