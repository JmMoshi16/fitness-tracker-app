import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';
import 'workout_camera_screen.dart';

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
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kOrange),
        ),
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
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.workout != null;
    final activeColor = AppTheme.getWorkoutColor(_type);
    final activeIcon = AppTheme.getWorkoutIcon(_type);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Workout' : 'Log Workout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: 'Workout Type'),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: _types.map((t) {
                          final selected = _type == t;
                          final color = AppTheme.getWorkoutColor(t);
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _type = t);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? LinearGradient(colors: [color.withOpacity(0.8), color], begin: Alignment.topLeft, end: Alignment.bottomRight)
                                    : null,
                                color: selected ? null : (isDark ? kDarkCard : kLightCard),
                                borderRadius: BorderRadius.circular(16),
                                border: selected ? null : Border.all(color: isDark ? kDarkBorder : kLightBorder),
                                boxShadow: selected
                                    ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(AppTheme.getWorkoutIcon(t), color: selected ? Colors.white : color, size: 28),
                                  const SizedBox(height: 8),
                                  Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected ? Colors.white : (isDark ? kDarkSubtext : kLightSubtext),
                                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      SectionHeader(title: 'Details'),
                      const SizedBox(height: 16),
                      FitInput(
                        controller: _titleCtrl,
                        label: 'Workout Title',
                        hint: 'e.g. Morning Run',
                        prefixIcon: Icons.title_rounded,
                        validator: (v) => v!.trim().isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FitInput(
                              controller: _durationCtrl,
                              label: 'Duration',
                              hint: 'Minutes',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.timer_rounded,
                              validator: (v) {
                                if (v!.trim().isEmpty) return 'Required';
                                if (int.tryParse(v.trim()) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: isDark ? kDarkCard : kLightCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? kDarkBorder : kLightBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, color: kOrange, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        DateFormat('MMM d, yyyy').format(DateTime.parse(_date)),
                                        style: TextStyle(
                                          color: isDark ? kDarkText : kLightText,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FitInput(
                        controller: _notesCtrl,
                        label: 'Notes (Optional)',
                        hint: 'How did it feel?',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      SectionHeader(title: 'Media'),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final result = await Navigator.push<File>(
                            context,
                            MaterialPageRoute(builder: (_) => const WorkoutCameraScreen()),
                          );
                          if (result != null) setState(() => _photo = result);
                        },
                        child: FitCard(
                          padding: EdgeInsets.zero,
                          showBorder: true,
                          child: _photo == null
                              ? Container(
                                  height: 120,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: kOrange.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.camera_alt_rounded, color: kOrange, size: 28),
                                      ),
                                      const SizedBox(height: 12),
                                      Text('Add Photo Proof', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file(_photo!, width: double.infinity, height: 200, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 12, right: 12,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _photo = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                                        ),
                                      ),
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
            
            // Sticky Bottom Panel
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? kDarkSurface : kLightSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  )
                ],
              ),
              child: FitButton(
                label: isEdit ? 'Save Changes' : 'Create Workout',
                icon: isEdit ? Icons.save_rounded : Icons.add_rounded,
                isLoading: _saving,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
