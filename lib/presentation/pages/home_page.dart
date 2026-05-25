import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'tracking_calendar_page.dart';
import 'summary_trends_page.dart';
import 'settings_page.dart';
import 'privacy_policy_page.dart';
import '../sheets/donation_sheet.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_background.dart';
import '../providers/cycle_provider.dart';
import '../providers/symptom_provider.dart';
import '../providers/tag_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TrackingCalendarPage(),
    const SummaryTrendsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.primaryDarkColor : AppTheme.primaryColor;

    return GlassBackground(
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  'assets/icon/app_icon_foreground.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Private Tracker",
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  fontFamily: AppTheme.fontFamily,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                DonationSheet.show(context);
              },
              icon: Icon(Icons.favorite_rounded, color: primary.withValues(alpha: 0.8), size: 22),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<CycleProvider>().refresh();
                context.read<SymptomProvider>().refresh();
                context.read<TagProvider>().refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Predictions updated"),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              icon: Icon(Icons.sync_rounded, color: primary.withValues(alpha: 0.6), size: 22),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                PrivacyPolicyPage.show(context);
              },
              icon: Icon(Icons.security_rounded, color: primary.withValues(alpha: 0.6), size: 22),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _pages[_currentIndex],
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Container(
            decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 32).copyWith(
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  if (_currentIndex != index) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentIndex = index);
                  }
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: primary,
                unselectedItemColor: primary.withValues(alpha: 0.3),
                showSelectedLabels: false,
                showUnselectedLabels: false,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_rounded), 
                    activeIcon: Icon(Icons.calendar_month_rounded),
                    label: "Calendar"
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_outlined), 
                    activeIcon: Icon(Icons.analytics_rounded),
                    label: "Trends"
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined), 
                    activeIcon: Icon(Icons.settings_rounded),
                    label: "Settings"
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
