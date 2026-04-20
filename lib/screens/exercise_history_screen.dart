import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/db_helper.dart';
import '../models/models.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);
const kCardDark = Color(0xFF16213E);

class ExerciseHistoryScreen extends StatefulWidget {
  const ExerciseHistoryScreen({super.key});
  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<ExerciseLog> _logs = [];
  List<PRRecord> _prs = [];
  bool _loading = true;
  String? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = DBHelper.currentUid;
    if (uid == null) return;
    final logs = await DBHelper.getExerciseLogs(uid);
    final prs = await DBHelper.getPRRecords(uid);
    if (mounted) setState(() { _logs = logs; _prs = prs; _loading = false; });
  }

  List<String> get _exerciseNames => _logs.map((l) => l.exerciseName).toSet().toList()..sort();

  List<ExerciseLog> get _filteredLogs => _selectedExercise == null
      ? _logs
      : _logs.where((l) => l.exerciseName == _selectedExercise).toList();

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
        title: const Text('Exercise History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: kGreen,
          labelColor: kGreen,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'PRs'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : TabBarView(
              controller: _tabCtrl,
              children: [_buildHistoryTab(), _buildPRTab()],
            ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Exercise filter
        if (_exerciseNames.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('All', _selectedExercise == null, () => setState(() => _selectedExercise = null)),
                ..._exerciseNames.map((e) => _filterChip(e, _selectedExercise == e, () => setState(() => _selectedExercise = e))),
              ],
            ),
          ),
        ],

        // Progression chart
        if (_selectedExercise != null) ...[
          const SizedBox(height: 16),
          _buildProgressionChart(),
        ],

        const SizedBox(height: 12),
        Expanded(
          child: _filteredLogs.isEmpty
              ? _emptyState('No exercise logs yet', 'Log exercises to see history')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredLogs.length,
                  itemBuilder: (_, i) => _logCard(_filteredLogs[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildProgressionChart() {
    final exerciseLogs = _logs
        .where((l) => l.exerciseName == _selectedExercise)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (exerciseLogs.length < 2) return const SizedBox.shrink();

    final spots = exerciseLogs.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.maxWeight)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_selectedExercise Progression',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}kg', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: kGreen,
                  barWidth: 3,
                  dotData: FlDotData(
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4, color: kGreen, strokeWidth: 2, strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: kGreen.withOpacity(0.1),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _logCard(ExerciseLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.fitness_center_rounded, color: kGreen, size: 20),
        ),
        title: Text(log.exerciseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          '${log.sets.length} sets · ${log.totalVolume.toStringAsFixed(1)}kg volume · ${log.date}',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        iconColor: Colors.white38,
        collapsedIconColor: Colors.white38,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _miniStat('${log.maxWeight}kg', 'Max Weight'),
                    _miniStat('${log.totalReps}', 'Total Reps'),
                    _miniStat('${log.totalVolume.toStringAsFixed(0)}kg', 'Volume'),
                  ],
                ),
                const SizedBox(height: 12),
                ...log.sets.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), shape: BoxShape.circle),
                        child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white54, fontSize: 11))),
                      ),
                      const SizedBox(width: 12),
                      Text('${e.value.weight}kg × ${e.value.reps} reps',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const Spacer(),
                      Icon(e.value.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: e.value.completed ? kGreen : Colors.white24, size: 18),
                    ],
                  ),
                )),
                if (log.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    child: Text(log.notes, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPRTab() {
    return _prs.isEmpty
        ? _emptyState('No PRs yet', 'Log exercises to track personal records')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _prs.length,
            itemBuilder: (_, i) => _prCard(_prs[i]),
          );
  }

  Widget _prCard(PRRecord pr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pr.exerciseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${pr.reps} reps · ${pr.date}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${pr.weight}kg', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 20)),
              const Text('PR', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? kGreen : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? kGreen : Colors.white12),
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white54,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
        ),
      );

  Widget _miniStat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      );

  Widget _emptyState(String title, String subtitle) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center_rounded, size: 56, color: Colors.white12),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
}
