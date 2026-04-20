import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/models.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);
const kCardDark = Color(0xFF16213E);

class WorkoutTemplatesScreen extends StatefulWidget {
  final Function(WorkoutTemplate)? onUseTemplate;
  const WorkoutTemplatesScreen({super.key, this.onUseTemplate});
  @override
  State<WorkoutTemplatesScreen> createState() => _WorkoutTemplatesScreenState();
}

class _WorkoutTemplatesScreenState extends State<WorkoutTemplatesScreen> {
  List<WorkoutTemplate> _templates = [];
  bool _loading = true;

  // Built-in templates
  final _builtIn = [
    WorkoutTemplate(userId: '', name: 'Push Day', category: 'Push',
        exercises: ['Bench Press', 'Overhead Press', 'Incline Dumbbell Press', 'Tricep Pushdown', 'Lateral Raises']),
    WorkoutTemplate(userId: '', name: 'Pull Day', category: 'Pull',
        exercises: ['Deadlift', 'Pull-ups', 'Barbell Row', 'Face Pulls', 'Bicep Curls']),
    WorkoutTemplate(userId: '', name: 'Leg Day', category: 'Legs',
        exercises: ['Squat', 'Romanian Deadlift', 'Leg Press', 'Leg Curl', 'Calf Raises']),
    WorkoutTemplate(userId: '', name: 'Full Body', category: 'Full Body',
        exercises: ['Squat', 'Bench Press', 'Deadlift', 'Pull-ups', 'Overhead Press']),
    WorkoutTemplate(userId: '', name: 'HIIT Cardio', category: 'Cardio',
        exercises: ['Burpees', 'Jump Squats', 'Mountain Climbers', 'Box Jumps', 'Sprint Intervals']),
  ];

  final _categoryColors = {
    'Push': const Color(0xFFEF5350),
    'Pull': const Color(0xFF42A5F5),
    'Legs': const Color(0xFF66BB6A),
    'Full Body': const Color(0xFFAB47BC),
    'Cardio': const Color(0xFFFF7043),
    'Custom': const Color(0xFF78909C),
  };

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final uid = DBHelper.currentUid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final list = await DBHelper.getTemplates(uid);
      if (mounted) setState(() { _templates = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('Failed to load templates: $e');
    }
  }

  void _showCreateDialog({WorkoutTemplate? template}) {
    final nameCtrl = TextEditingController(text: template?.name ?? '');
    final exercisesCtrl = TextEditingController(text: template?.exercises.join(', ') ?? '');
    String category = template?.category ?? 'Custom';
    final categories = ['Push', 'Pull', 'Legs', 'Full Body', 'Cardio', 'Custom'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(template == null ? 'Create Template' : 'Edit Template',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              _darkField(nameCtrl, 'Template Name', Icons.title_rounded),
              const SizedBox(height: 10),
              _darkField(exercisesCtrl, 'Exercises (comma separated)', Icons.fitness_center_rounded, maxLines: 3),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: kCardDark,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setS(() => category = v!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final uid = DBHelper.currentUid!;
                    final exercises = exercisesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                    final t = WorkoutTemplate(
                      id: template?.id,
                      userId: uid,
                      name: nameCtrl.text.trim(),
                      category: category,
                      exercises: exercises,
                    );
                    if (template == null) {
                      await DBHelper.insertTemplate(t);
                    } else {
                      await DBHelper.updateTemplate(t);
                    }
                    _loadTemplates();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: Text(template == null ? 'Create Template' : 'Save Changes',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
        title: const Text('Workout Templates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: kGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_rounded, color: kGreen, size: 20),
            ),
            onPressed: () => _showCreateDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Built-in Templates', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  ..._builtIn.map((t) => _templateCard(t, isBuiltIn: true)),
                  if (_templates.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('My Templates', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    ..._templates.map((t) => _templateCard(t, isBuiltIn: false)),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _templateCard(WorkoutTemplate t, {required bool isBuiltIn}) {
    final color = _categoryColors[t.category] ?? const Color(0xFF78909C);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(t.category[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
        ),
        title: Text(t.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('${t.exercises.length} exercises · ${t.category}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        iconColor: Colors.white38,
        collapsedIconColor: Colors.white38,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...t.exercises.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                        child: Center(child: Text('${e.key + 1}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 10),
                      Text(e.value, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          widget.onUseTemplate?.call(t);
                          Navigator.pop(context, t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [kGreen, kDarkGreen]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Use Template', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                    if (!isBuiltIn) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showCreateDialog(template: t),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await DBHelper.deleteTemplate(t.id!);
                          _loadTemplates();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: kGreen, size: 20),
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      );
}
