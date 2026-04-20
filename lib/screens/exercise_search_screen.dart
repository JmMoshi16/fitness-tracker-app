import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

class ExerciseSearchScreen extends StatefulWidget {
  const ExerciseSearchScreen({super.key});
  @override
  State<ExerciseSearchScreen> createState() => _ExerciseSearchScreenState();
}

class _ExerciseSearchScreenState extends State<ExerciseSearchScreen> {
  final _searchCtrl = TextEditingController();

  String? _selectedMuscle;
  String? _selectedType;
  String? _selectedDifficulty;

  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  final _muscles = ['biceps', 'triceps', 'chest', 'lats', 'middle_back', 'lower_back',
    'shoulders', 'abdominals', 'hamstrings', 'quadriceps', 'glutes', 'calves', 'forearms', 'traps', 'neck'];

  final _types = ['strength', 'cardio', 'stretching', 'plyometrics', 'powerlifting', 'olympic_weightlifting'];

  final _difficulties = ['beginner', 'intermediate', 'expert'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; _results = []; _searched = true; });
    try {
      final data = await ApiService.fetchNinjasExercises(
        muscle: _selectedMuscle,
        type: _selectedType,
        difficulty: _selectedDifficulty,
        name: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      if (mounted) setState(() { _results = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load exercises. Check your connection.'; _loading = false; });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedMuscle = null;
      _selectedType = null;
      _selectedDifficulty = null;
      _searchCtrl.clear();
      _results = [];
      _searched = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFilters = _selectedMuscle != null || _selectedType != null || _selectedDifficulty != null || _searchCtrl.text.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        title: const Text('Exercise Search', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (hasFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear', style: TextStyle(color: kOrange, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search + filters
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name search
                Row(
                  children: [
                    Expanded(
                      child: FitInput(
                        controller: _searchCtrl,
                        hint: 'Search by name (optional)...',
                        prefixIcon: Icons.search_rounded,
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () { HapticFeedback.mediumImpact(); _search(); },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [kOrange, kOrangeDark]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: kOrange.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Muscle chips
                _filterLabel('Muscle Group'),
                const SizedBox(height: 8),
                _chipRow(_muscles, _selectedMuscle, (v) => setState(() => _selectedMuscle = _selectedMuscle == v ? null : v)),
                const SizedBox(height: 12),

                // Type chips
                _filterLabel('Type'),
                const SizedBox(height: 8),
                _chipRow(_types, _selectedType, (v) => setState(() => _selectedType = _selectedType == v ? null : v)),
                const SizedBox(height: 12),

                // Difficulty chips
                _filterLabel('Difficulty'),
                const SizedBox(height: 8),
                Row(
                  children: _difficulties.map((d) {
                    final isSelected = _selectedDifficulty == d;
                    final color = d == 'beginner' ? const Color(0xFF4CAF50) : d == 'intermediate' ? const Color(0xFFFF9800) : const Color(0xFFEF5350);
                    return GestureDetector(
                      onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedDifficulty = isSelected ? null : d); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : (isDark ? kDarkCard : kLightCard),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? color : (isDark ? kDarkBorder : kLightBorder)),
                          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))] : [],
                        ),
                        child: Text(
                          _capitalize(d),
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? kDarkSubtext : kLightSubtext),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Search button
                FitButton(
                  label: 'Search Exercises',
                  icon: Icons.fitness_center_rounded,
                  onTap: _search,
                  isLoading: _loading,
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kOrange))
                : _error != null
                    ? _buildError(isDark)
                    : !_searched
                        ? _buildHint(isDark)
                        : _results.isEmpty
                            ? _buildEmpty(isDark)
                            : _buildResults(isDark),
          ),
        ],
      ),
    );
  }

  Widget _chipRow(List<String> items, String? selected, void Function(String) onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.map((item) {
          final isSelected = selected == item;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onTap(item); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [kOrange, kOrangeDark]) : null,
                color: isSelected ? null : (isDark ? kDarkCard : kLightCard),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: isDark ? kDarkBorder : kLightBorder),
                boxShadow: isSelected ? [BoxShadow(color: kOrange.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Text(
                _capitalize(item.replaceAll('_', ' ')),
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? kDarkSubtext : kLightSubtext),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final e = _results[i];
        final muscle     = _capitalize((e['muscle'] ?? '').toString().replaceAll('_', ' '));
        final type       = _capitalize((e['type'] ?? '').toString());
        final difficulty = _capitalize((e['difficulty'] ?? '').toString());
        final equipment  = _capitalize((e['equipment'] ?? '').toString());
        final instructions = (e['instructions'] ?? '').toString();
        final muscleColor = _muscleColor(muscle);
        final diffColor   = difficulty.toLowerCase() == 'beginner'
            ? const Color(0xFF4CAF50)
            : difficulty.toLowerCase() == 'intermediate'
                ? const Color(0xFFFF9800)
                : const Color(0xFFEF5350);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FitCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [muscleColor.withOpacity(0.7), muscleColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 22),
              ),
              title: Text(
                _capitalize(e['name'] ?? 'Exercise'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? kDarkText : kLightText),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _tag(muscle, muscleColor),
                    _tag(type, kInfo),
                    _tag(difficulty, diffColor),
                  ],
                ),
              ),
              iconColor: isDark ? kDarkSubtext : kLightSubtext,
              collapsedIconColor: isDark ? kDarkSubtext : kLightSubtext,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      if (equipment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.build_rounded, size: 14, color: isDark ? kDarkSubtext : kLightSubtext),
                            const SizedBox(width: 6),
                            Text('Equipment: $equipment', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        instructions.isNotEmpty ? instructions : 'No instructions available.',
                        style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHint(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: kOrange.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.search_rounded, size: 44, color: kOrange.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            Text('Search for exercises', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? kDarkText : kLightText)),
            const SizedBox(height: 6),
            Text('Select a muscle group, type, or difficulty\nthen tap Search', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded, color: isDark ? kDarkSubtext : kLightSubtext, size: 56),
      const SizedBox(height: 16),
      Text('No exercises found', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 16)),
      const SizedBox(height: 8),
      Text('Try different filters', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 13)),
    ]),
  );

  Widget _buildError(bool isDark) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off_rounded, color: isDark ? kDarkSubtext : kLightSubtext, size: 56),
      const SizedBox(height: 16),
      Text(_error!, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 14), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      SizedBox(width: 160, child: FitButton(label: 'Retry', icon: Icons.refresh_rounded, onTap: _search)),
    ]),
  );

  Widget _filterLabel(String text) => Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? kDarkSubtext : kLightSubtext, letterSpacing: 0.3));

  Widget _tag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  String _capitalize(String s) => s.isEmpty ? s : s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  Color _muscleColor(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('chest'))    return const Color(0xFFEF5350);
    if (m.contains('back') || m.contains('lats')) return const Color(0xFF42A5F5);
    if (m.contains('leg') || m.contains('quad') || m.contains('hamstring') || m.contains('glute') || m.contains('calve')) return const Color(0xFF4CAF50);
    if (m.contains('shoulder')) return const Color(0xFFAB47BC);
    if (m.contains('bicep') || m.contains('tricep') || m.contains('forearm')) return const Color(0xFFFF7043);
    if (m.contains('abdom') || m.contains('core')) return const Color(0xFFFFCA28);
    return kOrange;
  }
}
