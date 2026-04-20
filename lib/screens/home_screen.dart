import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'dashboard_screen.dart';
import 'progress_screen.dart';
import 'workouts_list_screen.dart';
import 'profile_screen.dart';
import 'step_counter_screen.dart';
import 'workout_form_screen.dart';
import '../db/db_helper.dart';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Real-time workouts stream for ProgressScreen
  Stream<List<Workout>> _workoutsStream() {
    final uid = DBHelper.currentUid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('workouts')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Workout.fromDoc(d)).toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  Future<void> _openForm() async {
    final uid = DBHelper.currentUid;
    if (uid == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutFormScreen(userId: uid)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      body: StreamBuilder<List<Workout>>(
        stream: _workoutsStream(),
        builder: (context, snap) {
          final workouts = snap.data ?? [];
          final screens = [
            const DashboardScreen(),
            const WorkoutsListScreen(),
            const SizedBox(),
            ProgressScreen(workouts: workouts),
            const ProfileScreen(onDataChanged: null),
          ];
          return screens[_selectedIndex == 2 ? 0 : _selectedIndex];
        },
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? kDarkSurface : kLightSurface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 24, offset: const Offset(0, -6))],
        border: Border(top: BorderSide(color: isDark ? kDarkBorder : kLightBorder, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded,          Icons.home_outlined,           'Home'),
              _navItem(1, Icons.fitness_center_rounded, Icons.fitness_center_outlined, 'Workouts'),

              // Center FAB
              GestureDetector(
                onTap: () { HapticFeedback.mediumImpact(); _openForm(); },
                child: Container(
                  width: 54, height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kOrange, kOrangeDark]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: kOrange.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),

              _navItem(3, Icons.bar_chart_rounded,       Icons.bar_chart_outlined,        'Progress'),
              _navItem(4, Icons.person_rounded,           Icons.person_outlined,           'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedIndex = index); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kOrange.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon, color: isSelected ? kOrange : (isDark ? kDarkSubtext : kLightSubtext), size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: isSelected ? kOrange : (isDark ? kDarkSubtext : kLightSubtext), fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
