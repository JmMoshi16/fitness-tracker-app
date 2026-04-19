import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'workout_form_screen.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  Color get _color {
    switch (workout.type) {
      case 'Cardio': return const Color(0xFFEF5350);
      case 'Strength': return const Color(0xFF42A5F5);
      case 'Flexibility': return const Color(0xFF66BB6A);
      case 'HIIT': return const Color(0xFFFF7043);
      case 'Sports': return const Color(0xFFAB47BC);
      default: return const Color(0xFF78909C);
    }
  }

  IconData get _icon {
    switch (workout.type) {
      case 'Cardio': return Icons.directions_run_rounded;
      case 'Strength': return Icons.fitness_center_rounded;
      case 'Flexibility': return Icons.self_improvement_rounded;
      case 'HIIT': return Icons.flash_on_rounded;
      case 'Sports': return Icons.sports_rounded;
      default: return Icons.sports_gymnastics_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = workout.photoPath != null && workout.photoPath!.isNotEmpty;
    final photoFile = hasPhoto ? File(workout.photoPath!) : null;
    final photoExists = photoFile != null && photoFile.existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: CustomScrollView(
        slivers: [
          // ── Hero app bar with photo ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: photoExists ? 300 : 200,
            pinned: true,
            backgroundColor: _color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutFormScreen(userId: workout.userId, workout: workout),
                    ),
                  );
                  if (result == true && context.mounted) Navigator.pop(context, true);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(workout.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              background: photoExists
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(photoFile!, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, _color.withOpacity(0.8)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_color, _color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(_icon, size: 80, color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats row ──────────────────────────────────────────
                  Row(
                    children: [
                      _statChip(Icons.category_rounded, workout.type, _color),
                      const SizedBox(width: 10),
                      _statChip(Icons.timer_rounded, '${workout.durationMinutes} min', Colors.orange),
                      const SizedBox(width: 10),
                      _statChip(Icons.calendar_today_rounded,
                          DateFormat('MMM d, yyyy').format(DateTime.parse(workout.date)), Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Photo section ──────────────────────────────────────
                  if (hasPhoto) ...[
                    _sectionTitle('Workout Photo'),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: photoExists
                          ? Image.file(photoFile!, width: double.infinity, height: 220, fit: BoxFit.cover)
                          : Container(
                              width: double.infinity,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
                                  SizedBox(height: 8),
                                  Text('Photo not available', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Notes section ──────────────────────────────────────
                  if (workout.notes.isNotEmpty) ...[
                    _sectionTitle('Notes'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Text(workout.notes, style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5)),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kDeepDark)),
            ],
          ),
        ),
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDeepDark),
      );
}
