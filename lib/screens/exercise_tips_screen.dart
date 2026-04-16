import 'package:flutter/material.dart';
import '../services/api_service.dart';

const kGreen = Color(0xFF8BC34A);

class ExerciseTipsScreen extends StatefulWidget {
  const ExerciseTipsScreen({super.key});
  @override
  State<ExerciseTipsScreen> createState() => _ExerciseTipsScreenState();
}

class _ExerciseTipsScreenState extends State<ExerciseTipsScreen> {
  List<Map<String, dynamic>> _exercises = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.fetchExercises();
      setState(() => _exercises = data);
    } catch (e) {
      setState(() => _error = 'Failed to load exercise tips.\nCheck your connection.');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _stripHtml(String html) => html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Exercise Tips',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: kGreen),
                    onPressed: _load,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Powered by wger REST API',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kGreen))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.wifi_off, size: 48, color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                Text(_error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _exercises.length,
                          itemBuilder: (_, i) {
                            final ex = _exercises[i];
                            final desc = _stripHtml(ex['description'] ?? '');
                            final colors = [
                              Colors.red, Colors.blue, Colors.green,
                              Colors.orange, Colors.purple, Colors.teal,
                              Colors.pink, Colors.indigo, Colors.cyan, Colors.amber,
                            ];
                            final color = colors[i % colors.length];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text('${i + 1}',
                                          style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex['name'] ?? 'Exercise ${i + 1}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          desc.isNotEmpty ? desc : 'No description available.',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
