import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);

class DataExportScreen extends StatefulWidget {
  final List<Workout> workouts;
  const DataExportScreen({super.key, required this.workouts});
  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _exporting = false;
  String? _exportedPath;

  Future<void> _exportCSV() async {
    setState(() => _exporting = true);
    try {
      final rows = <List<dynamic>>[
        ['Title', 'Type', 'Duration (min)', 'Date', 'Notes', 'Calories'],
        ...widget.workouts.map((w) => [
              w.title,
              w.type,
              w.durationMinutes,
              w.date,
              w.notes,
              w.durationMinutes * 6,
            ]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'fittracker_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);

      setState(() { _exportedPath = file.path; _exporting = false; });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('CSV exported successfully!'),
          ]),
          backgroundColor: kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      setState(() => _exporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _exportJSON() async {
    setState(() => _exporting = true);
    try {
      final json = widget.workouts.map((w) => w.toMap()).toList().toString();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'fittracker_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json);

      setState(() { _exportedPath = file.path; _exporting = false; });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('JSON exported successfully!'),
          ]),
          backgroundColor: kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMin = widget.workouts.fold(0, (s, w) => s + w.durationMinutes);
    final types = widget.workouts.map((w) => w.type).toSet().length;

    return Scaffold(
      backgroundColor: kDeepDark,
      appBar: AppBar(
        backgroundColor: kDeepDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Export Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Export Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem('${widget.workouts.length}', 'Workouts'),
                        _vDivider(),
                        _summaryItem('$totalMin', 'Minutes'),
                        _vDivider(),
                        _summaryItem('$types', 'Types'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text('Choose Format', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),

              // CSV Export
              _exportCard(
                icon: Icons.table_chart_rounded,
                color: kGreen,
                title: 'Export as CSV',
                subtitle: 'Compatible with Excel, Google Sheets',
                onTap: _exportCSV,
              ),
              const SizedBox(height: 12),

              // JSON Export
              _exportCard(
                icon: Icons.code_rounded,
                color: const Color(0xFF42A5F5),
                title: 'Export as JSON',
                subtitle: 'Raw data format for developers',
                onTap: _exportJSON,
              ),

              if (_exporting) ...[
                const SizedBox(height: 32),
                const Center(child: CircularProgressIndicator(color: kGreen)),
                const SizedBox(height: 12),
                const Center(child: Text('Exporting...', style: TextStyle(color: Colors.white54))),
              ],

              if (_exportedPath != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.check_circle_rounded, color: kGreen, size: 18),
                        SizedBox(width: 8),
                        Text('File saved!', style: TextStyle(color: kGreen, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      Text(_exportedPath!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _exportCard({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ),
      );

  Widget _summaryItem(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      );

  Widget _vDivider() => Container(width: 1, height: 36, color: Colors.white12);
}
