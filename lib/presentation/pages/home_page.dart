import 'package:flutter/material.dart';
import '../../domain/cycle_calculator.dart';
import '../theme/app_theme.dart';
import 'tracking_calendar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TrackingCalendarPage(),
    const Center(child: Text("Symptoms Log (Coming Soon)")),
    const Center(child: Text("Settings")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Cycle Tracker"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.security, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDEEF4), // Soft Pink
              Color(0xFFE6E6FA), // Lavender
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _pages[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.primaryColor.withOpacity(0.4),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Calendar"),
              BottomNavigationBarItem(icon: Icon(Icons.notes), label: "Symptoms"),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
            ],
          ),
        ),
      ),
    );
  }
}
