import 'package:flutter/material.dart';
import 'history_screen.dart';
import 'new_checkup_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    NewCheckupScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: const Color(0xFF0E8388).withValues(alpha: 0.14),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline_rounded, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.add_circle_rounded, color: Color(0xFF0E8388)),
                label: 'Tạo Ca Mới',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded, color: Color(0xFF64748B)),
                selectedIcon: Icon(Icons.history_toggle_off_rounded, color: Color(0xFF0E8388)),
                label: 'Lịch Sử Ca Khám',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
