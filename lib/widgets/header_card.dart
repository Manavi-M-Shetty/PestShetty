import 'package:flutter/material.dart';

/// A simple header card used on the Home page.
/// Shows app title, a subtitle, and a notification icon.
/// You can customize the title/subtitle by changing the constants
/// or by converting this to accept constructor parameters.
class HeaderCard extends StatelessWidget {
  const HeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Left spacer for visual balance (can be replaced with a logo)
            const SizedBox(width: 6),

            // Title and subtitle column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PlantCare',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Pests',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Right side action icon (notifications)
            IconButton(
              onPressed: () {
                // TODO: hook up to notifications page or actions
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications tapped')),
                );
              },
              icon: const Icon(Icons.notifications_none),
              tooltip: 'Notifications',
            ),
          ],
        ),
      ),
    );
  }
}