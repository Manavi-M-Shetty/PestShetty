import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.pushNamed(context, '/community');
    } else if (index == 2) {
      _openDetect();
    }
  }

  void _openDetect() {
    Navigator.pushNamed(context, '/detect');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF101715) // Deep forest green tone for dark mode
        : const Color(0xFFF5F8F6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(isDark),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(isDark),
                    const SizedBox(height: 24),
                    _buildTipCard(isDark),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'My Garden',
                      actionText: 'View All',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildGardenList(isDark),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor:
            isDark ? Colors.grey.shade900.withOpacity(0.9) : Colors.white.withOpacity(0.95),
        elevation: 8,
        height: 70,
        indicatorColor: isDark ? Colors.green.shade900 : Colors.green.shade100,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.green.shade700),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt, color: Colors.green.shade700),
            label: 'Community',
          ),
          NavigationDestination(
            icon: const Icon(Icons.camera_alt_outlined, size: 28),
            selectedIcon: Icon(Icons.camera_alt, color: Colors.green.shade700, size: 28),
            label: 'Detect',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Colors.green.shade700),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1916), const Color(0xFF13241E)]
              : [Colors.green.shade200, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back! 👋',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'How are your plants today?',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ClipOval(
                child: Image.asset('assets/images/icon_leaf.png'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SEARCH BAR
  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withOpacity(0.9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.green.shade100.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: isDark ? Colors.white70 : Colors.grey),
          const SizedBox(width: 12),
          Text(
            'Search for diseases, plants, tips...',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
          ),
        ],
      ),
    );
  }

  // TIP CARD
  Widget _buildTipCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.green.shade900, Colors.green.shade700]
              : [Colors.green.shade600, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.white, size: 36),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tip of the Day",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  "Water your plants early in the morning for better absorption.",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION HEADER
  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
        Text(
          actionText,
          style: TextStyle(
              color: isDark ? Colors.green.shade300 : Colors.green.shade700,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // GARDEN LIST
  Widget _buildGardenList(bool isDark) {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildGardenItemCard(
            title: "Detect Disease",
            subtitle: "Tap here to scan",
            imagePath: 'assets/images/sample_leaf.jpg',
            onTap: _openDetect,
            isPrimaryAction: true,
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          _buildGardenItemCard(
            title: "Apple Tree",
            subtitle: "Healthy",
            imagePath: 'assets/images/sample_leaf.jpg',
            onTap: () {},
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          _buildGardenItemCard(
            title: "Strawberry Patch",
            subtitle: "Checked: 2d ago",
            imagePath: 'assets/images/sample_leaf.jpg',
            onTap: () {},
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // GARDEN CARD
  Widget _buildGardenItemCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required VoidCallback onTap,
    required bool isDark,
    bool isPrimaryAction = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 160,
      decoration: BoxDecoration(
        color: isPrimaryAction
            ? (isDark ? Colors.green.shade900 : Colors.green.shade50)
            : (isDark ? Colors.grey.shade800 : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isPrimaryAction
            ? Border.all(color: Colors.green.shade400, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
