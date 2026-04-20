import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';
import '../db/db_helper.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Workout _workout;
  bool _isTimerActive = false;
  int _restSeconds = 60;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
  }

  void _saveWorkout() {
    DBHelper.updateWorkout(_workout);
  }

  void _addSet(ExerciseLog exercise) {
    setState(() {
      exercise.sets.add(ExerciseSet(reps: 0, weight: 0.0));
    });
    _saveWorkout();
  }

  void _toggleSetCompletion(ExerciseSet set) {
    setState(() {
      set.completed = !set.completed;
      if (set.completed) {
        _startRestTimer();
      }
    });
    _saveWorkout();
  }

  void _startRestTimer() {
    setState(() {
      _isTimerActive = true;
      _restSeconds = 60; // default 60s
    });
    // In a real app, use a Timer.periodic here to count down.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppTheme.getWorkoutColor(_workout.type);

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_workout.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${_workout.durationMinutes} min • ${_workout.type}', style: TextStyle(fontSize: 12, color: isDark ? kDarkSubtext : kLightSubtext)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Exercise List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 40),
                itemCount: _workout.exercises.length + 1, // +1 for add exercise button
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  if (index == _workout.exercises.length) {
                    return _buildAddExerciseButton();
                  }
                  return _buildExerciseCard(_workout.exercises[index]);
                },
              ),
            ),

            // Sticky Bottom Panel (Rest Timer & Quick Actions)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? kDarkSurface : kLightSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isTimerActive)
                    Container(
                      margin: const EdgeInsets.bottom(16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer_rounded, color: activeColor, size: 20),
                              const SizedBox(width: 8),
                              const Text('Rest Timer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('00:$_restSeconds', style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => setState(() => _isTimerActive = false),
                                child: Icon(Icons.close_rounded, color: isDark ? kDarkSubtext : kLightSubtext, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  FitButton(
                    label: 'Finish Workout',
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      await DBHelper.updateWorkout(_workout);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseLog exercise) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FitCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exercise.exerciseName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Icon(Icons.more_vert, color: isDark ? kDarkSubtext : kLightSubtext, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Previous: 3 sets x 60kg', // Placeholder for previous data
            style: TextStyle(color: isDark ? kDarkTertiary : kLightTertiary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          // Header Row for Sets
          Row(
            children: [
              const SizedBox(width: 32, child: Text('Set', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
              const Expanded(child: Center(child: Text('kg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)))),
              const Expanded(child: Center(child: Text('Reps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)))),
              const SizedBox(width: 40, child: Center(child: Icon(Icons.check_rounded, size: 16, color: Colors.grey))),
            ],
          ),
          const SizedBox(height: 8),
          
          // Sets List
          ...exercise.sets.asMap().entries.map((e) {
            final idx = e.key;
            final set = e.value;
            return _buildSetRow(idx + 1, set);
          }),
          
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _addSet(exercise);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: kOrange, size: 18),
                  SizedBox(width: 4),
                  Text('Add Set', style: TextStyle(color: kOrange, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int index, ExerciseSet set) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowBg = set.completed ? kSuccess.withOpacity(0.1) : (isDark ? kDarkSurface : kLightSurface);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('$index', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? kDarkText : kLightText)),
          ),
          Expanded(
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isDark ? kDarkCard : kLightCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? kDarkBorder : kLightBorder),
              ),
              child: Center(
                child: TextFormField(
                  initialValue: set.weight > 0 ? set.weight.toString() : '',
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: '-', isDense: true, contentPadding: EdgeInsets.zero),
                  onChanged: (val) {
                    set.weight = double.tryParse(val) ?? 0.0;
                    _saveWorkout();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isDark ? kDarkCard : kLightCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? kDarkBorder : kLightBorder),
              ),
              child: Center(
                child: TextFormField(
                  initialValue: set.reps > 0 ? set.reps.toString() : '',
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: '-', isDense: true, contentPadding: EdgeInsets.zero),
                  onChanged: (val) {
                    set.reps = int.tryParse(val) ?? 0;
                    _saveWorkout();
                  },
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _toggleSetCompletion(set);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: set.completed ? kSuccess : (isDark ? kDarkCard : kLightCard),
                borderRadius: BorderRadius.circular(8),
                border: set.completed ? null : Border.all(color: isDark ? kDarkBorder : kLightBorder),
              ),
              child: Icon(Icons.check_rounded, color: set.completed ? Colors.white : (isDark ? kDarkBorder : kLightBorder), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddExerciseButton() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final nameCtrl = TextEditingController();
        final catCtrl = TextEditingController();
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? kDarkCard : kLightCard,
            title: const Text('Add Exercise'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FitInput(controller: nameCtrl, label: 'Exercise Name', hint: 'e.g., Squat'),
                const SizedBox(height: 12),
                FitInput(controller: catCtrl, label: 'Muscle Group', hint: 'e.g., Legs'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white),
                child: const Text('Add'),
              ),
            ],
          ),
        );

        if (result == true && nameCtrl.text.isNotEmpty) {
          setState(() {
            _workout.exercises.add(ExerciseLog(
              userId: _workout.userId,
              workoutId: _workout.id ?? '',
              exerciseName: nameCtrl.text.trim(),
              muscleGroup: catCtrl.text.trim(),
              date: _workout.date,
              sets: [ExerciseSet(reps: 0, weight: 0.0)],
            ));
          });
          _saveWorkout();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: kOrange, size: 24),
            SizedBox(width: 8),
            Text('Add Custom Exercise', style: TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
