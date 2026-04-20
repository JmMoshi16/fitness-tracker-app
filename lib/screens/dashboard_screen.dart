import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/components.dart';
import '../models/models.dart';
import '../db/db_helper.dart';
import 'rest_timer_screen.dart' hide kGreen, kDeepDark;
import 'plate_calculator_screen.dart' hide kGreen, kDeepDark;
import 'data_export_screen.dart' hide kGreen, kDeepDark;
import 'exercise_history_screen.dart' hide kGreen, kDeepDark;
import 'cycling_tracker_screen.dart' hide kGreen, kDeepDark;
import 'ai_workout_generator_screen.dart' hide kGreen, kDeepDark;
import 'workout_camera_screen.dart' hide kGreen, kDeepDark;
import 'step_counter_screen.dart';
import 'nutrition_screen.dart';
import 'weather_screen.dart';
import 'exercise_search_screen.dart';
import 'route_planner_screen.dart';
class _ToolData {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;
  _ToolData(this.icon, this.label, this.sublabel, this.color, this.gradient, this.onTap);
}

/// Premium Dashboard Screen with modern UI
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Workout> _workouts = [];
  String _username = 'Athlete';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final uid = DBHelper.currentUid;
    if (uid != null) {
      final results = await Future.wait([
        DBHelper.getWorkouts(uid),
        DBHelper.getCurrentUser(),
      ]);
      if (mounted) {
        setState(() {
          _workouts = results[0] as List<Workout>;
          final user = results[1] as dynamic;
          if (user != null) _username = user.username;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<Workout> _getTodayWorkouts() {
    final today = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _workouts.where((w) => w.date == today).toList();
  }

  int _getWeeklyWorkouts() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    return _workouts.where((w) {
      final d = DateTime.tryParse(w.date);
      return d != null && !d.isBefore(startOfWeek) && !d.isAfter(now);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final todayWorkouts = _getTodayWorkouts();
    final totalMinutes = _workouts.fold(0, (sum, w) => sum + w.durationMinutes);
    final weeklyCount = _getWeeklyWorkouts();
    final weeklyGoal = 6;
    final progress = (weeklyCount / weeklyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: kOrange,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader(isDark, themeProvider)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                
                // Hero Stats Card
                SliverToBoxAdapter(child: _buildHeroCard(progress, weeklyCount, weeklyGoal, totalMinutes)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                
                // Quick Stats Row
                SliverToBoxAdapter(child: _buildQuickStats(totalMinutes)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                
                // Interactive Calendar
                SliverToBoxAdapter(child: _buildInteractiveCalendar()),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Today's Workouts
                SliverToBoxAdapter(child: _buildTodaySection(todayWorkouts)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Quick Tools Section
                SliverToBoxAdapter(child: _buildQuickToolsSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kOrange, kOrangeDark]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kOrange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: isDark ? kDarkSubtext : kLightSubtext,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _username,
                  style: TextStyle(
                    color: isDark ? kDarkText : kLightText,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          ThemeToggle(
            isDark: themeProvider.isDark,
            onToggle: themeProvider.toggle,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(double progress, int weeklyCount, int weeklyGoal, int totalMinutes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: HeroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Progress',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$weeklyCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: ' / $weeklyGoal',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'workouts this week',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                MiniStat(
                  icon: Icons.fitness_center_rounded,
                  value: '${_workouts.length}',
                  label: 'Total',
                ),
                const VerticalDivider(),
                MiniStat(
                  icon: Icons.timer_rounded,
                  value: '$totalMinutes',
                  label: 'Minutes',
                ),
                const VerticalDivider(),
                MiniStat(
                  icon: Icons.local_fire_department_rounded,
                  value: '${totalMinutes * 6}',
                  label: 'Calories',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(int totalMinutes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          StatTile(
            value: '${_workouts.length}',
            label: 'Workouts',
            icon: Icons.fitness_center_rounded,
            color: kOrange,
            isCompact: true,
          ),
          const SizedBox(width: 12),
          StatTile(
            value: '${(totalMinutes / 60).toStringAsFixed(1)}h',
            label: 'Hours',
            icon: Icons.schedule_rounded,
            color: kInfo,
            isCompact: true,
          ),
          const SizedBox(width: 12),
          StatTile(
            value: '${totalMinutes * 6}',
            label: 'Calories',
            icon: Icons.local_fire_department_rounded,
            color: kError,
            isCompact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection(List<Workout> todayWorkouts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayMin = todayWorkouts.fold(0, (sum, w) => sum + w.durationMinutes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                        ? "Today's Workouts"
                        : "Scheduled Workouts",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: isDark ? kDarkText : kLightText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${todayWorkouts.length} sessions · $todayMin min',
                    style: TextStyle(
                      color: isDark ? kDarkSubtext : kLightSubtext,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kOrange, kOrangeDark]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: kOrange.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (todayWorkouts.isEmpty)
            EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'No workouts today',
              subtitle: 'Start your fitness journey by adding a workout',
              actionLabel: 'Add Workout',
              onAction: () {},
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayWorkouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final workout = todayWorkouts[i];
                return Dismissible(
                  key: Key(workout.id ?? workout.hashCode.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: kError,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                  ),
                  onDismissed: (direction) async {
                    if (workout.id != null) {
                      await DBHelper.deleteWorkout(workout.id!);
                      _loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Workout deleted', style: TextStyle(color: Colors.white)), backgroundColor: kError),
                        );
                      }
                    }
                  },
                  child: WorkoutCard(
                    title: workout.title,
                    type: workout.type,
                    duration: workout.durationMinutes,
                    notes: workout.notes,
                    onTap: () {},
                    onEdit: () {},
                    onDelete: () {},
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCalendar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    // Show 3 days before, today, and 3 days after
    final days = List.generate(7, (i) => now.subtract(Duration(days: 3 - i)));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: isDark ? kDarkText : kLightText,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: TextStyle(
                  color: isDark ? kDarkSubtext : kLightSubtext,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((date) {
              final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
              final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(now);
              
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDate = date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(colors: [kOrange, kOrangeDark]) : null,
                    color: isSelected ? null : (isDark ? kDarkCard : kLightCard),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected ? null : Border.all(color: isDark ? kDarkBorder : kLightBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(date).substring(0, 1),
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : (isDark ? kDarkSubtext : kLightSubtext),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? kDarkText : kLightText),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: isToday && !isSelected ? kOrange : Colors.transparent,
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  Widget _buildQuickToolsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tools = [
      _ToolData(Icons.directions_walk_rounded, 'Steps',     'Counter',   const Color(0xFF9C27B0), [Color(0xFF9C27B0), Color(0xFF4A148C)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StepCounterScreen()))),
      _ToolData(Icons.restaurant_rounded,        'Nutrition', 'Analyser',  const Color(0xFF43A047), [Color(0xFF43A047), Color(0xFF1B5E20)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionScreen()))),
      _ToolData(Icons.wb_sunny_rounded,           'Weather',   'Outdoor',   const Color(0xFF1976D2), [Color(0xFF1976D2), Color(0xFF0D47A1)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen()))),
      _ToolData(Icons.manage_search_rounded,      'Ex. Search','By Muscle', const Color(0xFFFF7043), [Color(0xFFFF7043), Color(0xFFBF360C)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseSearchScreen()))),
      _ToolData(Icons.route_rounded,              'Route',     'Planner',   const Color(0xFF00897B), [Color(0xFF00897B), Color(0xFF004D40)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutePlannerScreen()))),
      _ToolData(Icons.timer_rounded,           'Rest Timer',  'Recovery',  const Color(0xFF4CAF50), [Color(0xFF4CAF50), Color(0xFF2E7D32)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RestTimerScreen()))),
      _ToolData(Icons.fitness_center_rounded,  'Plates',      'Calculator',const Color(0xFF42A5F5), [Color(0xFF42A5F5), Color(0xFF1565C0)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlateCalculatorScreen()))),
      _ToolData(Icons.directions_bike_rounded, 'Cycling',     'GPS Track', const Color(0xFF26C6DA), [Color(0xFF26C6DA), Color(0xFF00838F)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CyclingTrackerScreen()))),
      _ToolData(Icons.history_rounded,         'History',     'Exercise',  const Color(0xFFAB47BC), [Color(0xFFAB47BC), Color(0xFF6A1B9A)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseHistoryScreen()))),
      _ToolData(Icons.add_a_photo_rounded,     'Photos',      'Proof',     const Color(0xFFEF5350), [Color(0xFFEF5350), Color(0xFFB71C1C)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutCameraScreen()))),
      _ToolData(Icons.download_rounded,        'Export',      'Data',      const Color(0xFFFF7043), [Color(0xFFFF7043), Color(0xFFBF360C)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => DataExportScreen(workouts: _workouts)))),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick Tools', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: isDark ? kDarkText : kLightText, letterSpacing: -0.5)),
              Text('${tools.length + 1} tools', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),

          // Featured AI Gen card (full width)
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AIWorkoutGeneratorScreen()));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workout Generator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.3)),
                        SizedBox(height: 4),
                        Text('Generate a personalised plan instantly', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tool grid — 3 columns, 2 rows
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (_, i) => _buildToolCard(tools[i], isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(_ToolData tool, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        tool.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? kDarkCard : kLightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? kDarkBorder : kLightBorder, width: isDark ? 0.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: tool.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: tool.color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(tool.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              tool.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? kDarkText : kLightText),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              tool.sublabel,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: isDark ? kDarkSubtext : kLightSubtext),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
