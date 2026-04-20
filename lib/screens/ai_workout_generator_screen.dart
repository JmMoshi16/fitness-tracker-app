import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/models.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);
const kCardDark = Color(0xFF16213E);

class AIWorkoutGeneratorScreen extends StatefulWidget {
  const AIWorkoutGeneratorScreen({super.key});
  @override
  State<AIWorkoutGeneratorScreen> createState() => _AIWorkoutGeneratorScreenState();
}

class _AIWorkoutGeneratorScreenState extends State<AIWorkoutGeneratorScreen> {
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
    setState(() { _generating = true; _generatedWorkout = null; });

    Future.delayed(const Duration(milliseconds: 1200), () {
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
    final uid = DBHelper.currentUid!;
    final template = WorkoutTemplate(
      userId: uid,
      name: '$_goal - $_focus ($_level)',
      category: _focus,
      exercises: _generatedWorkout!.map((e) => e['name'] as String).toList(),
      notes: 'AI Generated: $_goal goal, $_level level',
    );
    await DBHelper.insertTemplate(template);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Saved as template!'),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDeepDark,
      appBar: AppBar(
        backgroundColor: kDeepDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Workout Generator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('AI Powered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Goal selector
              _sectionLabel('Your Goal'),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _goals.map((g) => _selectChip(g, _goal == g, () => setState(() => _goal = g))).toList(),
              ),
              const SizedBox(height: 20),

              // Level selector
              _sectionLabel('Fitness Level'),
              Row(
                children: _levels.map((l) => Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _selectChip(l, _level == l, () => setState(() => _level = l), fullWidth: true),
                ))).toList(),
              ),
              const SizedBox(height: 20),

              // Focus selector
              _sectionLabel('Workout Focus'),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _focuses.map((f) => _selectChip(f, _focus == f, () => setState(() => _focus = f))).toList(),
              ),
              const SizedBox(height: 28),

              // Generate button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _generating ? null : _generate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _generating
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Generating...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ])
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Generate Workout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                ),
              ),

              // Generated workout
              if (_generatedWorkout != null) ...[
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_goal · $_focus', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('$_level · ${_generatedWorkout!.length} exercises', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    GestureDetector(
                      onTap: _saveAsTemplate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: kGreen.withOpacity(0.3))),
                        child: const Row(children: [
                          Icon(Icons.save_rounded, color: kGreen, size: 16),
                          SizedBox(width: 6),
                          Text('Save', style: TextStyle(color: kGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._generatedWorkout!.asMap().entries.map((e) => _exerciseCard(e.key + 1, e.value)),
              ],

              // Recent history context
              if (_recentWorkouts.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Based on your recent activity', style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _recentWorkouts.map((w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                    child: Text(w.type, style: const TextStyle(color: Colors.white38, fontSize: 11)),
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

  Widget _exerciseCard(int num, Map<String, dynamic> e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('$num', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(e['muscle'], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${e['sets']} sets', style: const TextStyle(color: kGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${e['reps']} reps', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                Text('Rest: ${e['rest']}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      );

  Widget _selectChip(String label, bool selected, VoidCallback onTap, {bool fullWidth = false}) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7C3AED) : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? const Color(0xFF7C3AED) : Colors.white12),
            boxShadow: selected ? [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(color: selected ? Colors.white : Colors.white54,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ),
      );
}
