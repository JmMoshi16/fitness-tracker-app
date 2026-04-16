import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);

class ProgressScreen extends StatefulWidget {
  final List<Workout> workouts;
  const ProgressScreen({super.key, required this.workouts});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _selectedWeekOffset = 0; // 0 = this week

  List<DateTime> _getWeekDays(int offset) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7 + offset * 7));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  Map<String, int> _getDailyMinutes(List<DateTime> days) {
    final map = <String, int>{};
    for (final d in days) {
      final key = DateFormat('yyyy-MM-dd').format(d);
      map[key] = widget.workouts
          .where((w) => w.date == key)
          .fold(0, (s, w) => s + w.durationMinutes);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getWeekDays(_selectedWeekOffset);
    final dailyMin = _getDailyMinutes(days);
    final maxMin = dailyMin.values.isEmpty ? 1 : dailyMin.values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxMin == 0 ? 1 : maxMin;

    final totalMin = widget.workouts.fold(0, (s, w) => s + w.durationMinutes);
    final totalWorkouts = widget.workouts.length;
    final avgMin = totalWorkouts == 0 ? 0 : (totalMin / totalWorkouts).round();

    final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Statistic',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() => _selectedWeekOffset++),
                      ),
                      Text(
                        _selectedWeekOffset == 0
                            ? 'This Week'
                            : '${DateFormat('MMM d').format(days.first)} – ${DateFormat('MMM d').format(days.last)}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _selectedWeekOffset > 0
                            ? () => setState(() => _selectedWeekOffset--)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Calories / duration headline
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$totalMin ',
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
                    ),
                    const TextSpan(
                      text: 'min',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text('Target: ${totalWorkouts * 45} min',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),

              // Bar chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (i) {
                          final key = DateFormat('yyyy-MM-dd').format(days[i]);
                          final val = dailyMin[key] ?? 0;
                          final ratio = val / safeMax;
                          final isToday = key == today;
                          final pct = safeMax == 1 ? 0 : ((val / safeMax) * 100).round();

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (val > 0)
                                Text('$pct%',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isToday ? kGreen : Colors.grey,
                                        fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: 28,
                                height: (ratio * 100).clamp(4.0, 100.0),
                                decoration: BoxDecoration(
                                  color: isToday ? kGreen : const Color(0xFFDCEDC8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (i) {
                        final key = DateFormat('yyyy-MM-dd').format(days[i]);
                        final isToday = key == today;
                        return Text(dayLabels[i],
                            style: TextStyle(
                                fontSize: 11,
                                color: isToday ? kGreen : Colors.grey,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal));
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.fitness_center,
                      iconColor: kGreen,
                      label: 'Exercise',
                      value: '$totalWorkouts',
                      unit: 'sessions',
                      barColor: kGreen,
                      barValue: (totalWorkouts / 30).clamp(0.0, 1.0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      icon: Icons.favorite,
                      iconColor: Colors.red,
                      label: 'BPM',
                      value: '86',
                      unit: 'avg bpm',
                      barColor: Colors.red,
                      barValue: 0.72,
                      isHeartRate: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.monitor_weight_outlined,
                      iconColor: Colors.orange,
                      label: 'Avg Duration',
                      value: '$avgMin',
                      unit: 'min/session',
                      barColor: Colors.orange,
                      barValue: (avgMin / 60).clamp(0.0, 1.0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      icon: Icons.water_drop,
                      iconColor: Colors.blue,
                      label: 'Water',
                      value: '${(totalMin * 0.02).toStringAsFixed(1)}',
                      unit: 'liters',
                      barColor: Colors.blue,
                      barValue: ((totalMin * 0.02) / 3).clamp(0.0, 1.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Workout type breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Workout Breakdown',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    ..._buildTypeBreakdown(),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTypeBreakdown() {
    final types = ['Cardio', 'Strength', 'Flexibility', 'HIIT', 'Sports', 'Other'];
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.grey];
    final total = widget.workouts.length;
    if (total == 0) {
      return [const Center(child: Text('No workouts yet', style: TextStyle(color: Colors.grey)))];
    }
    return List.generate(types.length, (i) {
      final count = widget.workouts.where((w) => w.type == types[i]).length;
      if (count == 0) return const SizedBox.shrink();
      final ratio = count / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(types[i], style: const TextStyle(fontSize: 13)),
                Text('$count sessions', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: colors[i].withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(colors[i]),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required Color barColor,
    required double barValue,
    bool isHeartRate = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          if (isHeartRate)
            // Simple heartbeat line visual
            SizedBox(
              height: 30,
              child: CustomPaint(painter: _HeartRatePainter(color: barColor)),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barValue,
                backgroundColor: barColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 6,
              ),
            ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF212121))),
                TextSpan(
                    text: ' $unit',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartRatePainter extends CustomPainter {
  final Color color;
  _HeartRatePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, h * 0.5);
    path.lineTo(w * 0.2, h * 0.5);
    path.lineTo(w * 0.3, h * 0.1);
    path.lineTo(w * 0.4, h * 0.9);
    path.lineTo(w * 0.5, h * 0.3);
    path.lineTo(w * 0.6, h * 0.5);
    path.lineTo(w * 0.7, h * 0.5);
    path.lineTo(w * 0.8, h * 0.2);
    path.lineTo(w * 0.9, h * 0.7);
    path.lineTo(w, h * 0.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HeartRatePainter old) => old.color != color;
}
