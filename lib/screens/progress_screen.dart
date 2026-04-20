import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

class ProgressScreen extends StatefulWidget {
  final List<Workout> workouts;
  const ProgressScreen({super.key, required this.workouts});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PRRecord> _prs = [];
  bool _loadingPRs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPRs();
  }

  Future<void> _loadPRs() async {
    final uid = DBHelper.currentUid;
    if (uid != null) {
      final prs = await DBHelper.getPRRecords(uid);
      if (mounted) setState(() { _prs = prs; _loadingPRs = false; });
    } else {
      if (mounted) setState(() => _loadingPRs = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        title: const Text('Progress', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kOrange,
          unselectedLabelColor: isDark ? kDarkSubtext : kLightSubtext,
          indicatorColor: kOrange,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Volume'),
            Tab(text: 'PRs'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildVolumeTab(),
            _buildPRsTab(),
          ],
        ),
      ),
    );
  }

  // ── Overview Tab ─────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.workouts.length;
    final totalMin = widget.workouts.fold(0, (s, w) => s + w.durationMinutes);
    final totalHrs = (totalMin / 60).toStringAsFixed(1);
    final avgMin = total == 0 ? '0' : (totalMin / total).toStringAsFixed(0);

    // Workouts per type
    final typeCounts = <String, int>{};
    for (final w in widget.workouts) {
      typeCounts[w.type] = (typeCounts[w.type] ?? 0) + 1;
    }

    // Streak calculation
    final streak = _calcStreak();

    return RefreshIndicator(
      onRefresh: _loadPRs,
      color: kOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kOrange, kOrangeDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: kOrange.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _heroStat('$total', 'Workouts', Icons.fitness_center_rounded),
                  _divider(),
                  _heroStat('${totalHrs}h', 'Total Time', Icons.schedule_rounded),
                  _divider(),
                  _heroStat('$streak🔥', 'Day Streak', Icons.local_fire_department_rounded),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Avg duration card
            Row(
              children: [
                Expanded(child: _statMiniCard('Avg Duration', '$avgMin min', Icons.timer_rounded, kInfo)),
                const SizedBox(width: 12),
                Expanded(child: _statMiniCard('This Week', '${_weeklyCount()}', Icons.calendar_today_rounded, kOrange)),
              ],
            ),
            const SizedBox(height: 24),

            // Workout type breakdown
            if (typeCounts.isNotEmpty) ...[
              SectionHeader(title: 'Workout Breakdown'),
              const SizedBox(height: 16),
              FitCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: typeCounts.entries.map((e) {
                    final color = AppTheme.getWorkoutColor(e.key);
                    final pct = total == 0 ? 0.0 : e.value / total;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(AppTheme.getWorkoutIcon(e.key), color: color, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.key, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? kDarkText : kLightText, fontSize: 13))),
                              Text('${e.value}x · ${(pct * 100).round()}%', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: color.withOpacity(0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else
              EmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'No workouts yet',
                subtitle: 'Log your first workout to see progress stats',
              ),
          ],
        ),
      ),
    );
  }

  // ── Volume Tab ────────────────────────────────────────────────────────────
  Widget _buildVolumeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      double volume = 0;
      for (final w in widget.workouts.where((w) => w.date == dateStr)) {
        for (final ex in w.exercises) {
          for (final set in ex.sets) {
            if (set.completed) volume += set.reps * set.weight;
          }
        }
        volume += w.durationMinutes * 1.0; // fallback: count minutes as proxy
      }
      spots.add(FlSpot(6 - i.toDouble(), volume));
    }

    final maxVol = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxVol == 0 ? 500.0 : maxVol * 1.3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Weekly Activity (last 7 days)'),
          const SizedBox(height: 16),
          FitCard(
            padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => FlLine(color: isDark ? kDarkBorder : kLightBorder, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i > 6) return const Text('');
                          final date = now.subtract(Duration(days: 6 - i));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(DateFormat('E').format(date), style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0, maxX: 6, minY: 0, maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: kOrange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: kOrange, strokeWidth: 2, strokeColor: isDark ? kDarkCard : kLightCard),
                      ),
                      belowBarData: BarAreaData(show: true, color: kOrange.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly summary
          SectionHeader(title: 'Monthly Summary'),
          const SizedBox(height: 16),
          _buildMonthlySummary(isDark, now),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(bool isDark, DateTime now) {
    final months = <String, int>{};
    for (int i = 2; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM').format(m);
      months[key] = 0;
    }
    for (final w in widget.workouts) {
      final d = DateTime.tryParse(w.date);
      if (d == null) continue;
      final key = DateFormat('MMM').format(d);
      if (months.containsKey(key)) months[key] = months[key]! + 1;
    }
    final maxCount = months.values.fold(0, (a, b) => a > b ? a : b);

    return FitCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: months.entries.map((e) {
          final pct = maxCount == 0 ? 0.0 : e.value / maxCount;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${e.value}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? kDarkText : kLightText, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 80 * pct + 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kOrange, kOrangeDark], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Text(e.key, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── PRs Tab ───────────────────────────────────────────────────────────────
  Widget _buildPRsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingPRs) {
      return const Center(child: CircularProgressIndicator(color: kOrange));
    }

    if (_prs.isEmpty) {
      return EmptyState(
        icon: Icons.emoji_events_rounded,
        title: 'No PRs yet',
        subtitle: 'Complete workouts with exercises to track personal records',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _prs.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        if (i == 0) return SectionHeader(title: 'Personal Records (${_prs.length})');
        final pr = _prs[i - 1];
        return _buildPRCard(pr, isDark);
      },
    );
  }

  Widget _buildPRCard(PRRecord pr, bool isDark) {
    return FitCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pr.exerciseName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? kDarkText : kLightText)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: isDark ? kDarkSubtext : kLightSubtext),
                    const SizedBox(width: 4),
                    Text(pr.date, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.repeat_rounded, size: 12, color: isDark ? kDarkSubtext : kLightSubtext),
                    const SizedBox(width: 4),
                    Text('${pr.reps} reps', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${pr.weight}', style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 22)),
              Text('kg', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _heroStat(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 48, color: Colors.white24);

  Widget _statMiniCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FitCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: isDark ? kDarkText : kLightText, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  int _calcStreak() {
    if (widget.workouts.isEmpty) return 0;
    final dates = widget.workouts.map((w) => w.date).toSet();
    int streak = 0;
    var day = DateTime.now();
    while (dates.contains(DateFormat('yyyy-MM-dd').format(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _weeklyCount() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    return widget.workouts.where((w) {
      final d = DateTime.tryParse(w.date);
      return d != null && !d.isBefore(startOfWeek) && !d.isAfter(now);
    }).length;
  }
}
