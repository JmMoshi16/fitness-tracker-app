import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/models.dart';
import 'workout_camera_screen.dart';
import 'workout_timer_screen.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);

class WorkoutFormScreen extends StatefulWidget {
  final String userId;
  final Workout? workout;
  const WorkoutFormScreen({super.key, required this.userId, this.workout});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'Cardio';
  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _saving = false;
  File? _photo;

  final _types = ['Cardio', 'Strength', 'Flexibility', 'HIIT', 'Sports', 'Other'];

  final _typeIcons = {
    'Cardio': Icons.directions_run,
    'Strength': Icons.fitness_center,
    'Flexibility': Icons.self_improvement,
    'HIIT': Icons.flash_on,
    'Sports': Icons.sports,
    'Other': Icons.sports_gymnastics,
  };

  final _typeColors = {
    'Cardio': Colors.red,
    'Strength': Colors.blue,
    'Flexibility': Colors.green,
    'HIIT': Colors.orange,
    'Sports': Colors.purple,
    'Other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _titleCtrl.text = widget.workout!.title;
      _durationCtrl.text = widget.workout!.durationMinutes.toString();
      _notesCtrl.text = widget.workout!.notes;
      _type = widget.workout!.type;
      _date = widget.workout!.date;
      if (widget.workout!.photoPath != null && widget.workout!.photoPath!.isNotEmpty) {
        _photo = File(widget.workout!.photoPath!);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: kGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final w = Workout(
        id: widget.workout?.id,
        userId: widget.userId,
        title: _titleCtrl.text.trim(),
        type: _type,
        durationMinutes: int.parse(_durationCtrl.text.trim()),
        notes: _notesCtrl.text.trim(),
        date: _date,
        photoPath: _photo?.path ?? widget.workout?.photoPath ?? '',
      );
      if (widget.workout == null) {
        await DBHelper.insertWorkout(w);
      } else {
        await DBHelper.updateWorkout(w);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.workout != null;
    final activeColor = _typeColors[_type] ?? kGreen;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: activeColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isEdit ? 'Edit Workout' : 'Log Workout',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [activeColor, activeColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(_typeIcons[_type], size: 80, color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type selector
                    const Text('Workout Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.4,
                      children: _types.map((t) {
                        final selected = _type == t;
                        final color = _typeColors[t]!;
                        return GestureDetector(
                          onTap: () => setState(() => _type = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? LinearGradient(colors: [color.withOpacity(0.8), color], begin: Alignment.topLeft, end: Alignment.bottomRight)
                                  : null,
                              color: selected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: selected
                                  ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]
                                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_typeIcons[t], color: selected ? Colors.white : color, size: 24),
                                const SizedBox(height: 4),
                                Text(t,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: selected ? Colors.white : Colors.grey,
                                        fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    _sectionLabel('Workout Title'),
                    _inputCard(
                      child: TextFormField(
                        controller: _titleCtrl,
                        decoration: _inputDeco('e.g. Morning Run', Icons.title_rounded),
                        validator: (v) => v!.trim().isEmpty ? 'Enter a title' : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Duration
                    _sectionLabel('Duration'),
                    _inputCard(
                      child: TextFormField(
                        controller: _durationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco('Minutes', Icons.timer_rounded),
                        validator: (v) {
                          if (v!.trim().isEmpty) return 'Enter duration';
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) return 'Enter valid minutes';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date
                    _sectionLabel('Date'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: _inputCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, color: activeColor, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(_date)),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    _sectionLabel('Notes (optional)'),
                    _inputCard(
                      child: TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: _inputDeco('Add any notes...', Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Timer button
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutTimerScreen())),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_rounded, color: Colors.orange, size: 20),
                            SizedBox(width: 10),
                            Text('Start Workout Timer', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Camera proof button
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push<File>(
                          context,
                          MaterialPageRoute(builder: (_) => const WorkoutCameraScreen()),
                        );
                        if (result != null) setState(() => _photo = result);
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: _photo == null
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_rounded, color: kGreen, size: 20),
                                    SizedBox(width: 10),
                                    Text('Add Workout Photo Proof', style: TextStyle(color: kGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(_photo!, width: double.infinity, height: 180, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _photo = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isEdit ? Icons.save_rounded : Icons.add_circle_outline, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEdit ? 'Save Changes' : 'Log Workout',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF333333))),
      );

  Widget _inputCard({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: child,
      );

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: kGreen, size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
}
