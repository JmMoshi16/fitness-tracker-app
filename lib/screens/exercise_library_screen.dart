import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});
  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  List<Map<String, dynamic>> _exercises = [];
  List<String> _muscles = [];
  List<String> _equipment = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _error = false;

  String _search = '';
  String? _selectedMuscle;
  String? _selectedEquipment;
  bool _isGridView = false;

  int _offset = 0;
  static const _pageSize = 20;
  bool _hasMore = true;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadExercises(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadFilters() async {
    try {
      final results = await Future.wait([
        ApiService.fetchBodyParts(),
        ApiService.fetchEquipment(),
      ]);
      if (mounted) {
        setState(() {
          _muscles   = results[0] as List<String>;
          _equipment = results[1] as List<String>;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadExercises({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = false; _offset = 0; _hasMore = true; _exercises = []; });
    }
    try {
      final data = await ApiService.fetchExerciseDB(limit: _pageSize, offset: reset ? 0 : _offset);
      if (mounted) {
        setState(() {
          _exercises.addAll(data);
          _offset += data.length;
          _hasMore = data.length == _pageSize;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final data = await ApiService.fetchExerciseDB(limit: _pageSize, offset: _offset);
      if (mounted) {
        setState(() {
          _exercises.addAll(data);
          _offset += data.length;
          _hasMore = data.length == _pageSize;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _exercises.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      final muscle = (e['primaryMuscles'] ?? e['muscle'] ?? '').toString().toLowerCase();
      final equip  = (e['equipment'] ?? '').toString().toLowerCase();

      final matchSearch = _search.isEmpty || name.contains(_search.toLowerCase());
      final matchMuscle = _selectedMuscle == null ||
          muscle.contains(_selectedMuscle!.toLowerCase());
      final matchEquip  = _selectedEquipment == null ||
          equip.contains(_selectedEquipment!.toLowerCase());

      return matchSearch && matchMuscle && matchEquip;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        title: const Text('Exercise Library'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () { HapticFeedback.lightImpact(); setState(() => _isGridView = !_isGridView); },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadExercises(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: FitInput(
              controller: _searchCtrl,
              hint: 'Search exercises...',
              prefixIcon: Icons.search_rounded,
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // Muscle filter chips
          if (_muscles.isNotEmpty) _buildFilterRow(
            items: _muscles,
            selected: _selectedMuscle,
            onSelect: (v) => setState(() => _selectedMuscle = _selectedMuscle == v ? null : v),
            label: 'Muscle',
          ),

          // Equipment filter chips
          if (_equipment.isNotEmpty) _buildFilterRow(
            items: _equipment,
            selected: _selectedEquipment,
            onSelect: (v) => setState(() => _selectedEquipment = _selectedEquipment == v ? null : v),
            label: 'Equipment',
          ),

          // Active filter badges + count
          if (_selectedMuscle != null || _selectedEquipment != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Text('${filtered.length} results', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() { _selectedMuscle = null; _selectedEquipment = null; }),
                    child: const Text('Clear filters', style: TextStyle(color: kOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kOrange))
                : _error
                    ? _buildErrorState()
                    : filtered.isEmpty
                        ? _buildEmptyState()
                        : _isGridView
                            ? _buildGrid(filtered)
                            : _buildList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required List<String> items,
    required String? selected,
    required void Function(String) onSelect,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: items.map((item) {
          final isSelected = selected == item;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onSelect(item); },
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
                _capitalize(item),
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

  Widget _buildList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: items.length + (_loadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == items.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: kOrange)));
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildExerciseCard(items[i], isGrid: false),
        );
      },
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length + (_loadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == items.length) return const Center(child: CircularProgressIndicator(color: kOrange));
        return _buildExerciseCard(items[i], isGrid: true);
      },
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> e, {required bool isGrid}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name    = _capitalize(e['name'] ?? 'Unknown');
    final gifUrl  = e['gifUrl'] ?? e['gif_url'] ?? '';
    final muscle  = _capitalize((e['primaryMuscles'] is List
        ? (e['primaryMuscles'] as List).join(', ')
        : e['primaryMuscles'] ?? e['muscle'] ?? 'General').toString());
    final equip   = _capitalize((e['equipment'] ?? '').toString());
    final level   = _capitalize((e['level'] ?? e['difficulty'] ?? '').toString());

    final muscleColor = _muscleColor(muscle);

    if (isGrid) {
      return FitCard(
        padding: EdgeInsets.zero,
        onTap: () => _showDetail(e),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GIF / placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: gifUrl.isNotEmpty
                  ? Image.network(gifUrl, height: 130, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gifPlaceholder(muscleColor))
                  : _gifPlaceholder(muscleColor),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? kDarkText : kLightText, height: 1.2)),
                  const SizedBox(height: 6),
                  _tag(muscle, muscleColor),
                  if (equip.isNotEmpty) ...[const SizedBox(height: 4), _tag(equip, isDark ? kDarkSubtext : kLightSubtext)],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // List card
    return FitCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showDetail(e),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // GIF thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: gifUrl.isNotEmpty
                    ? Image.network(gifUrl, width: 64, height: 64, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _gifPlaceholder(muscleColor, size: 64))
                    : _gifPlaceholder(muscleColor, size: 64),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? kDarkText : kLightText)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _tag(muscle, muscleColor),
                        if (equip.isNotEmpty) _tag(equip, isDark ? kDarkSubtext : kLightSubtext),
                        if (level.isNotEmpty) _tag(level, _levelColor(level)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: isDark ? kDarkSubtext : kLightSubtext),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name       = _capitalize(e['name'] ?? 'Unknown');
    final gifUrl     = e['gifUrl'] ?? e['gif_url'] ?? '';
    final muscle     = _capitalize((e['primaryMuscles'] is List
        ? (e['primaryMuscles'] as List).join(', ')
        : e['primaryMuscles'] ?? e['muscle'] ?? '').toString());
    final secondary  = (e['secondaryMuscles'] is List ? (e['secondaryMuscles'] as List).join(', ') : '').toString();
    final equip      = _capitalize((e['equipment'] ?? '').toString());
    final level      = _capitalize((e['level'] ?? e['difficulty'] ?? '').toString());
    final instructions = e['instructions'] is List
        ? (e['instructions'] as List).join('\n\n')
        : (e['instructions'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? kDarkSurface : kLightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? kDarkBorder : kLightBorder, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              if (gifUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(gifUrl, height: 220, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gifPlaceholder(_muscleColor(muscle), size: 220)),
                ),
              const SizedBox(height: 20),
              Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: isDark ? kDarkText : kLightText)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (muscle.isNotEmpty)  _tag(muscle, _muscleColor(muscle), large: true),
                if (equip.isNotEmpty)   _tag(equip, isDark ? kDarkSubtext : kLightSubtext, large: true),
                if (level.isNotEmpty)   _tag(level, _levelColor(level), large: true),
              ]),
              if (secondary.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Secondary Muscles', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? kDarkSubtext : kLightSubtext)),
                const SizedBox(height: 6),
                Text(_capitalize(secondary), style: TextStyle(color: isDark ? kDarkText : kLightText, fontSize: 14)),
              ],
              if (instructions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Instructions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? kDarkText : kLightText)),
                const SizedBox(height: 10),
                Text(instructions, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 14, height: 1.6)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _gifPlaceholder(Color color, {double size = double.infinity}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size == double.infinity ? null : size,
      height: size == double.infinity ? 130 : size,
      color: color.withOpacity(0.1),
      child: Icon(Icons.fitness_center_rounded, color: color, size: size == double.infinity ? 36 : size * 0.4),
    );
  }

  Widget _tag(String label, Color color, {bool large = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: large ? 12 : 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: isDark ? kDarkSubtext : kLightSubtext, size: 56),
          const SizedBox(height: 16),
          Text('Failed to load exercises', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(width: 160, child: FitButton(label: 'Retry', icon: Icons.refresh_rounded, onTap: () => _loadExercises(reset: true))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: isDark ? kDarkSubtext : kLightSubtext, size: 56),
          const SizedBox(height: 16),
          Text('No exercises found', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 16)),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  Color _muscleColor(String muscle) {
    final m = muscle.toLowerCase();
    if (m.contains('chest'))    return const Color(0xFFEF5350);
    if (m.contains('back'))     return const Color(0xFF42A5F5);
    if (m.contains('leg') || m.contains('quad') || m.contains('hamstring')) return const Color(0xFF4CAF50);
    if (m.contains('shoulder')) return const Color(0xFFAB47BC);
    if (m.contains('arm') || m.contains('bicep') || m.contains('tricep'))   return const Color(0xFFFF7043);
    if (m.contains('core') || m.contains('abs')) return const Color(0xFFFFCA28);
    return kOrange;
  }

  Color _levelColor(String level) {
    final l = level.toLowerCase();
    if (l.contains('begin'))    return const Color(0xFF4CAF50);
    if (l.contains('inter'))    return const Color(0xFFFF9800);
    if (l.contains('advan') || l.contains('expert')) return const Color(0xFFEF5350);
    return kOrange;
  }
}
