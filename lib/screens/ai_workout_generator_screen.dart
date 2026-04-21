import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/db_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

class WorkoutGeneratorScreen extends StatefulWidget {
  const WorkoutGeneratorScreen({super.key});
  @override
  State<WorkoutGeneratorScreen> createState() => _WorkoutGeneratorScreenState();
}

class _WorkoutGeneratorScreenState extends State<WorkoutGeneratorScreen> {
  String _goal = 'Muscle Gain';
  String _level = 'Intermediate';
  String _focus = 'Full Body';
  bool _generating = false;
  List<Map<String, dynamic>>? _generatedWorkout;
  List<Workout> _recentWorkouts = [];

  final _goals = ['Muscle Gain', 'Fat Loss', 'Endurance', 'Strength', 'Flexibility'];
  final _levels = ['Beginner', 'Intermediate', 'Advanced'];
  final _focuses = ['Full Body', 'Push', 'Pull', 'Legs', 'Cardio', 'Core'];

  // Workout database by goal + focus
  final _workoutDB = {
    'Muscle Gain': {
      'Full Body': [
        {'name': 'Squat', 'sets': 4, 'reps': '8-10', 'rest': '90s', 'muscle': 'Legs'},
        {'name': 'Bench Press', 'sets': 4, 'reps': '8-10', 'rest': '90s', 'muscle': 'Chest'},
        {'name': 'Deadlift', 'sets': 3, 'reps': '6-8', 'rest': '120s', 'muscle': 'Back'},
        {'name': 'Overhead Press', 'sets': 3, 'reps': '8-10', 'rest': '90s', 'muscle': 'Shoulders'},
        {'name': 'Pull-ups', 'sets': 3, 'reps': '8-12', 'rest': '90s', 'muscle': 'Back'},
      ],
      'Push': [
        {'name': 'Bench Press', 'sets': 4, 'reps': '8-10', 'rest': '90s', 'muscle': 'Chest'},
        {'name': 'Incline Dumbbell Press', 'sets': 3, 'reps': '10-12', 'rest': '75s', 'muscle': 'Chest'},
        {'name': 'Overhead Press', 'sets': 3, 'reps': '8-10', 'rest': '90s', 'muscle': 'Shoulders'},
        {'name': 'Lateral Raises', 'sets': 3, 'reps': '12-15', 'rest': '60s', 'muscle': 'Shoulders'},
        {'name': 'Tricep Pushdown', 'sets': 3, 'reps': '12-15', 'rest': '60s', 'muscle': 'Triceps'},
      ],
      'Pull': [
        {'name': 'Deadlift', 'sets': 4, 'reps': '5-6', 'rest': '120s', 'muscle': 'Back'},
        {'name': 'Barbell Row', 'sets': 4, 'reps': '8-10', 'rest': '90s', 'muscle': 'Back'},
        {'name': 'Pull-ups', 'sets': 3, 'reps': '8-12', 'rest': '90s', 'muscle': 'Back'},
        {'name': 'Face Pulls', 'sets': 3, 'reps': '15-20', 'rest': '60s', 'muscle': 'Rear Delts'},
        {'name': 'Bicep Curls', 'sets': 3, 'reps': '12-15', 'rest': '60s', 'muscle': 'Biceps'},
      ],
      'Legs': [
        {'name': 'Squat', 'sets': 4, 'reps': '8-10', 'rest': '120s', 'muscle': 'Quads'},
        {'name': 'Romanian Deadlift', 'sets': 3, 'reps': '10-12', 'rest': '90s', 'muscle': 'Hamstrings'},
        {'name': 'Leg Press', 'sets': 3, 'reps': '12-15', 'rest': '90s', 'muscle': 'Quads'},
        {'name': 'Leg Curl', 'sets': 3, 'reps': '12-15', 'rest': '75s', 'muscle': 'Hamstrings'},
        {'name': 'Calf Raises', 'sets': 4, 'reps': '15-20', 'rest': '60s', 'muscle': 'Calves'},
      ],
    },
    'Fat Loss': {
      'Full Body': [
        {'name': 'Burpees', 'sets': 4, 'reps': '15', 'rest': '45s', 'muscle': 'Full Body'},
        {'name': 'Jump Squats', 'sets': 4, 'reps': '15', 'rest': '45s', 'muscle': 'Legs'},
        {'name': 'Mountain Climbers', 'sets': 3, 'reps': '30s', 'rest': '30s', 'muscle': 'Core'},
        {'name': 'Push-ups', 'sets': 3, 'reps': '15-20', 'rest': '45s', 'muscle': 'Chest'},
        {'name': 'Kettlebell Swings', 'sets': 4, 'reps': '20', 'rest': '45s', 'muscle': 'Full Body'},
      ],
      'Cardio': [
        {'name': 'Sprint Intervals', 'sets': 8, 'reps': '30s on/30s off', 'rest': '30s', 'muscle': 'Full Body'},
        {'name': 'Jump Rope', 'sets': 5, 'reps': '1 min', 'rest': '30s', 'muscle': 'Full Body'},
        {'name': 'Box Jumps', 'sets': 4, 'reps': '10', 'rest': '60s', 'muscle': 'Legs'},
        {'name': 'Battle Ropes', 'sets': 4, 'reps': '30s', 'rest': '30s', 'muscle': 'Arms/Core'},
        {'name': 'Rowing Machine', 'sets': 3, 'reps': '2 min', 'rest': '60s', 'muscle': 'Full Body'},
      ],
    },
    'Strength': {
      'Full Body': [
        {'name': 'Squat', 'sets': 5, 'reps': '5', 'rest': '180s', 'muscle': 'Legs'},
        {'name': 'Bench Press', 'sets': 5, 'reps': '5', 'rest': '180s', 'muscle': 'Chest'},
        {'name': 'Deadlift', 'sets': 3, 'reps': '3-5', 'rest': '240s', 'muscle': 'Back'},
        {'name': 'Overhead Press', 'sets': 5, 'reps': '5', 'rest': '180s', 'muscle': 'Shoulders'},
        {'name': 'Barbell Row', 'sets': 5, 'reps': '5', 'rest': '180s', 'muscle': 'Back'},
      ],
    },
    'Endurance': {
      'Cardio': [
        {'name': 'Steady State Run', 'sets': 1, 'reps': '30-45 min', 'rest': '-', 'muscle': 'Full Body'},
        {'name': 'Cycling', 'sets': 1, 'reps': '45-60 min', 'rest': '-', 'muscle': 'Legs'},
        {'name': 'Swimming', 'sets': 1, 'reps': '30 min', 'rest': '-', 'muscle': 'Full Body'},
        {'name': 'Jump Rope', 'sets': 5, 'reps': '3 min', 'rest': '1 min', 'muscle': 'Full Body'},
        {'name': 'Stair Climber', 'sets': 1, 'reps': '20 min', 'rest': '-', 'muscle': 'Legs'},
      ],
    },
    'Flexibility': {
      'Full Body': [
        {'name': 'Hip Flexor Stretch', 'sets': 3, 'reps': '30s each', 'rest': '15s', 'muscle': 'Hips'},
        {'name': 'Hamstring Stretch', 'sets': 3, 'reps': '30s each', 'rest': '15s', 'muscle': 'Hamstrings'},
        {'name': 'Shoulder Stretch', 'sets': 3, 'reps': '30s each', 'rest': '15s', 'muscle': 'Shoulders'},
        {'name': 'Cat-Cow Stretch', 'sets': 3, 'reps': '10 reps', 'rest': '15s', 'muscle': 'Spine'},
        {'name': 'Pigeon Pose', 'sets': 2, 'reps': '60s each', 'rest': '15s', 'muscle': 'Hips'},
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uid = DBHelper.currentUid;
    if (uid == null) return;
    final workouts = await DBHelper.getWorkouts(uid);
    if (mounted) setState(() => _recentWorkouts = workouts.take(5).toList());
  }

  void _generate() {
    HapticFeedback.mediumImpact();
    setState(() { _generating = true; _generatedWorkout = null; });

    Future.delayed(const Duration(milliseconds: 800), () {
      final goalData = _workoutDB[_goal] ?? _workoutDB['Muscle Gain']!;
      final focusData = goalData[_focus] ?? goalData.values.first;

      // Adjust based on level
      final adjusted = focusData.map((e) {
        final sets = _level == 'Beginner' ? (e['sets'] as int) - 1 : _level == 'Advanced' ? (e['sets'] as int) + 1 : e['sets'] as int;
        return {...e, 'sets': sets.clamp(2, 6)};
      }).toList();

      if (mounted) setState(() { _generatedWorkout = adjusted; _generating = false; });
    });
  }

  Future<void> _saveAsTemplate() async {
    if (_generatedWorkout == null) return;
    HapticFeedback.lightImpact();
    final uid = DBHelper.currentUid!;
    final template = WorkoutTemplate(
      userId: uid,
      name: '$_goal - $_focus ($_level)',
      category: _focus,
      exercises: _generatedWorkout!.map((e) => e['name'] as String).toList(),
      notes: 'Generated: $_goal goal, $_level level',
    );
    await DBHelper.insertTemplate(template);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Saved as template!', style: TextStyle(color: Colors.white)),
        backgroundColor: kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        backgroundColor: isDark ? kDarkBg : kLightBg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? kDarkText : kLightText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Workout Generator', style: TextStyle(color: isDark ? kDarkText : kLightText, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Smart Generator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Build Your Perfect\nWorkout Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Personalized routines based on your goals and fitness level',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Goal selector
              SectionHeader(title: 'Your Goal'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _goals.map((g) => _selectChip(g, _goal == g, () => setState(() => _goal = g), isDark)).toList(),
              ),
              const SizedBox(height: 28),

              // Level selector
              SectionHeader(title: 'Fitness Level'),
              const SizedBox(height: 12),
              Row(
                children: _levels.map((l) => Expanded(child: Padding(
                  padding: EdgeInsets.only(right: l == _levels.last ? 0 : 10),
                  child: _levelCard(l, _level == l, () => setState(() => _level = l), isDark),
                ))).toList(),
              ),
              const SizedBox(height: 28),

              // Focus selector
              SectionHeader(title: 'Workout Focus'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: _focuses.map((f) => _selectChip(f, _focus == f, () => setState(() => _focus = f), isDark)).toList(),
              ),
              const SizedBox(height: 32),

              // Generate button
              SizedBox(
                width: double.infinity,
                child: FitButton(
                  label: _generating ? 'Generating...' : 'Generate Workout',
                  icon: Icons.auto_awesome_rounded,
                  onTap: _generate,
                  isLoading: _generating,
                ),
              ),

              // Generated workout
              if (_generatedWorkout != null) ...[
                const SizedBox(height: 32),
                FitCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$_goal Workout', style: TextStyle(color: isDark ? kDarkText : kLightText, fontWeight: FontWeight.w700, fontSize: 18)),
                                const SizedBox(height: 4),
                                Text('$_focus · $_level · ${_generatedWorkout!.length} exercises', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _saveAsTemplate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: kSuccess.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kSuccess.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.bookmark_rounded, color: kSuccess, size: 16),
                                  SizedBox(width: 6),
                                  Text('Save', style: TextStyle(color: kSuccess, fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._generatedWorkout!.asMap().entries.map((e) => _exerciseCard(e.key + 1, e.value, isDark)),
                    ],
                  ),
                ),
              ],

              // Recent history
              if (_recentWorkouts.isNotEmpty) ...[
                const SizedBox(height: 32),
                SectionHeader(title: 'Recent Activity'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _recentWorkouts.map((w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? kDarkCard : kLightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? kDarkBorder : kLightBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppTheme.getWorkoutIcon(w.type), size: 12, color: AppTheme.getWorkoutColor(w.type)),
                        const SizedBox(width: 6),
                        Text(w.type, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exerciseCard(int num, Map<String, dynamic> e, bool isDark) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? kDarkSurface : kLightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? kDarkBorder : kLightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(child: Text('$num', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e['name'], style: TextStyle(color: isDark ? kDarkText : kLightText, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(e['muscle'], style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${e['sets']} × ${e['reps']}', style: const TextStyle(color: kOrange, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const SizedBox(height: 4),
                Text('Rest: ${e['rest']}', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _selectChip(String label, bool selected, VoidCallback onTap, bool isDark) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]) : null,
            color: selected ? null : (isDark ? kDarkCard : kLightCard),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? Colors.transparent : (isDark ? kDarkBorder : kLightBorder)),
            boxShadow: selected ? [
              BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ] : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : (isDark ? kDarkText : kLightText),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );

  Widget _levelCard(String label, bool selected, VoidCallback onTap, bool isDark) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: selected ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]) : null,
            color: selected ? null : (isDark ? kDarkCard : kLightCard),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? Colors.transparent : (isDark ? kDarkBorder : kLightBorder), width: selected ? 0 : 1),
            boxShadow: selected ? [
              BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : (isDark ? kDarkText : kLightText),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
}
