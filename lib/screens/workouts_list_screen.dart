import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';
import 'workout_form_screen.dart';

class WorkoutsListScreen extends StatefulWidget {
  const WorkoutsListScreen({super.key});
  @override
  State<WorkoutsListScreen> createState() => _WorkoutsListScreenState();
}

class _WorkoutsListScreenState extends State<WorkoutsListScreen> {
  String _search = '';
  String? _filterType;
  String? _filterDate;
  final _searchCtrl = TextEditingController();
  final _types = ['Cardio', 'Strength', 'Flexibility', 'HIIT', 'Sports', 'Other'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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

  List<Workout> _applyFilters(List<Workout> all) {
    return all.where((w) {
      final matchSearch = _search.isEmpty || w.title.toLowerCase().contains(_search.toLowerCase());
      final matchType   = _filterType == null || w.type == _filterType;
      final matchDate   = _filterDate == null || w.date == _filterDate;
      return matchSearch && matchType && matchDate;
    }).toList();
  }

  Future<void> _delete(Workout w) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Workout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "${w.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kError, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && w.id != null) {
      await DBHelper.deleteWorkout(w.id!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Workout deleted'), backgroundColor: kError, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    }
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kOrange)), child: child!),
    );
    if (picked != null) setState(() => _filterDate = DateFormat('yyyy-MM-dd').format(picked));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFilter = _filterType != null || _filterDate != null || _search.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Workouts', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (hasFilter)
            TextButton(
              onPressed: () => setState(() { _filterType = null; _filterDate = null; _search = ''; _searchCtrl.clear(); }),
              child: const Text('Clear', style: TextStyle(color: kOrange, fontWeight: FontWeight.w600)),
            ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: kOrange, size: 28),
            onPressed: () async {
              final uid = DBHelper.currentUid;
              if (uid == null) return;
              await Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutFormScreen(userId: uid)));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: FitInput(
              controller: _searchCtrl,
              hint: 'Search workouts...',
              prefixIcon: Icons.search_rounded,
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // Type filter chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _chip('All', _filterType == null, () => setState(() => _filterType = null)),
                ..._types.map((t) => _chip(t, _filterType == t, () => setState(() => _filterType = _filterType == t ? null : t))),
                _chip('📅 Date', _filterDate != null, _pickFilterDate),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Real-time list
          Expanded(
            child: StreamBuilder<List<Workout>>(
              stream: _workoutsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kOrange));
                }
                if (snap.hasError) {
                  return EmptyState(icon: Icons.error_outline_rounded, title: 'Error', subtitle: snap.error.toString());
                }
                final all      = snap.data ?? [];
                final filtered = _applyFilters(all);

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: hasFilter ? 'No matching workouts' : 'No workouts yet',
                    subtitle: hasFilter ? 'Try clearing filters' : 'Tap + to log your first workout',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorkoutCard(
                      workout: filtered[i],
                      onEdit: () async {
                        final uid = DBHelper.currentUid;
                        if (uid == null) return;
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutFormScreen(userId: uid, workout: filtered[i])));
                      },
                      onDelete: () => _delete(filtered[i]),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutDetailViewScreen(workout: filtered[i]))),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [kOrange, kOrangeDark]) : null,
          color: selected ? null : (isDark ? kDarkCard : kLightCard),
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: isDark ? kDarkBorder : kLightBorder),
          boxShadow: selected ? [BoxShadow(color: kOrange.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : (isDark ? kDarkSubtext : kLightSubtext), fontWeight: selected ? FontWeight.bold : FontWeight.w500, fontSize: 12)),
      ),
    );
  }
}

// ── Individual workout card ──────────────────────────────────────────────────
class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap, onEdit, onDelete;
  const _WorkoutCard({required this.workout, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final color   = AppTheme.getWorkoutColor(workout.type);
    final icon    = AppTheme.getWorkoutIcon(workout.type);
    final hasPhoto = workout.photoPath != null && workout.photoPath!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: FitCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo thumbnail if exists
            if (hasPhoto)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.file(File(workout.photoPath!), height: 160, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withOpacity(0.7), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workout.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? kDarkText : kLightText), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _tag(workout.type, color),
                            const SizedBox(width: 8),
                            Icon(Icons.timer_outlined, size: 13, color: isDark ? kDarkSubtext : kLightSubtext),
                            const SizedBox(width: 3),
                            Text('${workout.durationMinutes} min', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12)),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_rounded, size: 13, color: isDark ? kDarkSubtext : kLightSubtext),
                            const SizedBox(width: 3),
                            Text(workout.date, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12)),
                          ],
                        ),
                        if (workout.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(workout.notes, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? kDarkTertiary : kLightTertiary, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _iconBtn(Icons.edit_outlined, kInfo, onEdit),
                      const SizedBox(height: 6),
                      _iconBtn(Icons.delete_outline_rounded, kError, onDelete),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
  );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: () { HapticFeedback.lightImpact(); onTap(); },
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}

// ── Workout Detail View Screen ───────────────────────────────────────────────
class WorkoutDetailViewScreen extends StatelessWidget {
  final Workout workout;
  const WorkoutDetailViewScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final color    = AppTheme.getWorkoutColor(workout.type);
    final icon     = AppTheme.getWorkoutIcon(workout.type);
    final hasPhoto = workout.photoPath != null && workout.photoPath!.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      body: CustomScrollView(
        slivers: [
          // Hero app bar with photo or gradient
          SliverAppBar(
            expandedHeight: hasPhoto ? 280 : 200,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                ),
                onPressed: () async {
                  final uid = DBHelper.currentUid;
                  if (uid == null) return;
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutFormScreen(userId: uid, workout: workout)));
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: hasPhoto
                  ? GestureDetector(
                      onTap: () => _viewPhoto(context, workout.photoPath!),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(workout.photoPath!), fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _gradientBg(color, icon)),
                          // Gradient overlay
                          Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                          Positioned(
                            bottom: 16, right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                              child: const Row(children: [Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14), SizedBox(width: 4), Text('Tap to view', style: TextStyle(color: Colors.white, fontSize: 11))]),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _gradientBg(color, icon),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & type
                  Text(workout.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, color: isDark ? kDarkText : kLightText, letterSpacing: -0.5)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _detailTag(workout.type, color),
                      _detailTag('${workout.durationMinutes} min', kInfo),
                      _detailTag(workout.date, isDark ? kDarkSubtext : kLightSubtext),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats cards
                  Row(
                    children: [
                      _statCard('Duration', '${workout.durationMinutes}', 'min', Icons.timer_rounded, kOrange, isDark),
                      const SizedBox(width: 12),
                      _statCard('Volume', '${(workout.volume ?? 0).toStringAsFixed(0)}', 'kg', Icons.fitness_center_rounded, kInfo, isDark),
                      const SizedBox(width: 12),
                      _statCard('Calories', '${(workout.durationMinutes * 6)}', 'kcal', Icons.local_fire_department_rounded, kError, isDark),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Notes
                  if (workout.notes.isNotEmpty) ...[
                    SectionHeader(title: 'Notes'),
                    const SizedBox(height: 12),
                    FitCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(workout.notes, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 14, height: 1.6)),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Exercises
                  if (workout.exercises.isNotEmpty) ...[
                    SectionHeader(title: 'Exercises (${workout.exercises.length})'),
                    const SizedBox(height: 12),
                    ...workout.exercises.map((ex) => _exerciseCard(ex, isDark)),
                  ],

                  // Photo section
                  if (hasPhoto) ...[
                    const SizedBox(height: 8),
                    SectionHeader(title: 'Workout Photo'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _viewPhoto(context, workout.photoPath!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(File(workout.photoPath!), width: double.infinity, height: 220, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(BuildContext context, String path) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _PhotoViewScreen(path: path)));
  }

  Widget _gradientBg(Color color, IconData icon) => Container(
    decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.8), color], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Center(child: Icon(icon, color: Colors.white.withOpacity(0.4), size: 80)),
  );

  Widget _detailTag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
  );

  Widget _statCard(String label, String value, String unit, IconData icon, Color color, bool isDark) => Expanded(
    child: FitCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          RichText(text: TextSpan(children: [
            TextSpan(text: value, style: TextStyle(color: isDark ? kDarkText : kLightText, fontWeight: FontWeight.w800, fontSize: 18)),
            TextSpan(text: '\n$unit', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 10)),
          ], style: const TextStyle(height: 1.3)), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 10)),
        ],
      ),
    ),
  );

  Widget _exerciseCard(ExerciseLog ex, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: FitCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.fitness_center_rounded, color: kOrange, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(ex.exerciseName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? kDarkText : kLightText))),
              Text(ex.muscleGroup, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 11)),
            ],
          ),
          if (ex.sets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              _setHeader('Set', isDark), _setHeader('Weight', isDark), _setHeader('Reps', isDark), _setHeader('Done', isDark),
            ]),
            ...ex.sets.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                _setCell('${e.key + 1}', isDark),
                _setCell('${e.value.weight}kg', isDark),
                _setCell('${e.value.reps}', isDark),
                Expanded(child: Center(child: Icon(e.value.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: e.value.completed ? kSuccess : (isDark ? kDarkBorder : kLightBorder), size: 18))),
              ]),
            )),
          ],
        ],
      ),
    ),
  );

  Widget _setHeader(String t, bool isDark) => Expanded(child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? kDarkSubtext : kLightSubtext), textAlign: TextAlign.center));
  Widget _setCell(String t, bool isDark) => Expanded(child: Text(t, style: TextStyle(fontSize: 12, color: isDark ? kDarkText : kLightText), textAlign: TextAlign.center));
}

// ── Full-screen photo viewer ─────────────────────────────────────────────────
class _PhotoViewScreen extends StatelessWidget {
  final String path;
  const _PhotoViewScreen({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Photo', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(File(path), fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64)),
        ),
      ),
    );
  }
}
