import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/models.dart';
import 'workout_form_screen.dart';
import 'workout_camera_screen.dart';
import 'exercise_tips_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'workout_detail_screen.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);
const kCardDark = Color(0xFF16213E);
const kBg = Color(0xFFF4F6F9);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Workout> _workouts = [];
  List<Workout> _filtered = [];
  String _username = '';
  int _selectedIndex = 0;
  String _filterType = 'All';
  DateTime _selectedDay = DateTime.now();

  final _types = ['All', 'Cardio', 'Strength', 'Flexibility', 'HIIT', 'Sports', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? 'Athlete');
    await _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final uid = DBHelper.currentUid;
    if (uid == null) return;
    final list = await DBHelper.getWorkouts(uid);
    setState(() {
      _workouts = list;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    _filtered = _workouts.where((w) {
      final typeMatch = _filterType == 'All' || w.type == _filterType;
      return typeMatch && w.date == dateStr;
    }).toList();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await DBHelper.logoutUser();
    }
  }

  Future<void> _deleteWorkout(Workout w) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Workout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "${w.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.deleteWorkout(w.id!);
      _loadWorkouts();
    }
  }

  Future<void> _openForm({Workout? workout}) async {
    final uid = DBHelper.currentUid;
    if (uid == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutFormScreen(userId: uid, workout: workout)),
    );
    if (result == true) _loadWorkouts();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final weekWorkouts = _workouts.where((w) {
      final d = DateTime.tryParse(w.date);
      return d != null && !d.isBefore(startOfWeek) && !d.isAfter(now);
    }).length;
    const goal = 6;
    final progress = (weekWorkouts / goal).clamp(0.0, 1.0);
    final totalMin = _workouts.fold(0, (s, w) => s + w.durationMinutes);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kDeepDark, kCardDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kGreen, kDarkGreen]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : 'A',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5)),
                        Text(_username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.white54, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Hero stats card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kGreen, kDarkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: kGreen.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Weekly Progress', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$weekWorkouts',
                                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: ' / $goal',
                                    style: const TextStyle(color: Colors.white60, fontSize: 18, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const Text('workouts this week', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: CircularProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 6,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _miniStat(Icons.fitness_center_rounded, '${_workouts.length}', 'Total'),
                        _vDivider(),
                        _miniStat(Icons.timer_rounded, '$totalMin', 'Minutes'),
                        _vDivider(),
                        _miniStat(Icons.local_fire_department_rounded, '${totalMin * 6}', 'Calories'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label) => Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _vDivider() => Container(width: 1, height: 28, color: Colors.white24);

  // ── CALENDAR STRIP ─────────────────────────────────────────────────────────
  Widget _buildCalendarStrip() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final labels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MMMM yyyy').format(_selectedDay),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDeepDark)),
              Text(DateFormat('EEE, d').format(_selectedDay),
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = days[i];
              final key = DateFormat('yyyy-MM-dd').format(day);
              final isSelected = key == DateFormat('yyyy-MM-dd').format(_selectedDay);
              final isToday = key == DateFormat('yyyy-MM-dd').format(now);
              final hasWorkout = _workouts.any((w) => w.date == key);

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDay = day;
                  _applyFilter();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 42,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? kDeepDark : (isToday ? kGreen.withOpacity(0.08) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: isToday && !isSelected ? Border.all(color: kGreen, width: 1.5) : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: kDeepDark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                        : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                  ),
                  child: Column(
                    children: [
                      Text(labels[i],
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white54 : Colors.grey,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text('${day.day}',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : (isToday ? kGreen : kDeepDark))),
                      const SizedBox(height: 6),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: hasWorkout ? (isSelected ? Colors.white : kGreen) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── WORKOUT LIST ────────────────────────────────────────────────────────────
  Widget _buildWorkoutSection() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final todayMin = _filtered.fold(0, (s, w) => s + w.durationMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Workouts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDeepDark)),
                  Text('${_filtered.length} sessions · $todayMin min',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              GestureDetector(
                onTap: () => _openForm(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kGreen, kDarkGreen]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kGreen.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Filter chips
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final t = _types[i];
              final selected = _filterType == t;
              return GestureDetector(
                onTap: () => setState(() {
                  _filterType = t;
                  _applyFilter();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? kDeepDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: selected ? kDeepDark.withOpacity(0.25) : Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(t,
                      style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : Colors.grey,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        if (_filtered.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filtered.length,
            itemBuilder: (_, i) => _workoutCard(_filtered[i]),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kDeepDark.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center_rounded, size: 36, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('No workouts logged', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDeepDark)),
            const SizedBox(height: 6),
            const Text('Hit "Add" to log your session', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _workoutCard(Workout w) {
    final color = _typeColor(w.type);
    return Dismissible(
      key: Key(w.id ?? w.title),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        await _deleteWorkout(w);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: w)),
              );
              if (result == true) _loadWorkouts();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.7), color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Icon(_typeIcon(w.type), color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDeepDark),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(w.type, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.timer_outlined, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text('${w.durationMinutes} min', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                        if (w.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(w.notes,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _actionBtn(Icons.edit_outlined, Colors.blue, () => _openForm(workout: w)),
                      const SizedBox(height: 6),
                      _actionBtn(Icons.delete_outline_rounded, Colors.red, () => _deleteWorkout(w)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
      );

  Color _typeColor(String type) {
    switch (type) {
      case 'Cardio': return const Color(0xFFEF5350);
      case 'Strength': return const Color(0xFF42A5F5);
      case 'Flexibility': return const Color(0xFF66BB6A);
      case 'HIIT': return const Color(0xFFFF7043);
      case 'Sports': return const Color(0xFFAB47BC);
      default: return const Color(0xFF78909C);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Cardio': return Icons.directions_run_rounded;
      case 'Strength': return Icons.fitness_center_rounded;
      case 'Flexibility': return Icons.self_improvement_rounded;
      case 'HIIT': return Icons.flash_on_rounded;
      case 'Sports': return Icons.sports_rounded;
      default: return Icons.sports_gymnastics_rounded;
    }
  }

  // ── MAIN BUILD ──────────────────────────────────────────────────────────────
  Widget _buildHomeBody() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kBg,
        body: RefreshIndicator(
          color: kGreen,
          onRefresh: _loadWorkouts,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildCalendarStrip()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildWorkoutSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeBody(),
      ProgressScreen(workouts: _workouts),
      const SizedBox(),
      const ExerciseTipsScreen(),
      ProfileScreen(onDataChanged: _loadData),
    ];

    return Scaffold(
      body: screens[_selectedIndex == 2 ? 0 : _selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _navItem(1, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Progress'),
              // Center FAB-style button
              GestureDetector(
                onTap: () => _openForm(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kGreen, kDarkGreen]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: kGreen.withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
              _navItem(3, Icons.lightbulb_rounded, Icons.lightbulb_outlined, 'Tips'),
              _navItem(4, Icons.person_rounded, Icons.person_outlined, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 0) _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kGreen.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : inactiveIcon, color: isSelected ? kGreen : Colors.grey, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? kGreen : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
