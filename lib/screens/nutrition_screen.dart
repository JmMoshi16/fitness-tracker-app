import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _ctrl = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;

  // Quick-pick common foods
  final _quickPicks = [
    '100g chicken breast',
    '1 cup white rice',
    '1 large egg',
    '100g broccoli',
    '1 medium banana',
    '30g oats',
    '100g salmon',
    '1 cup whole milk',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _analyse() async {
    final query = _ctrl.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final data = await ApiService.analyseNutrition(query);
      if (mounted) setState(() { _result = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not analyse. Try a different format e.g. "100g chicken".'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        title: const Text('Nutrition Analyser', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF43A047).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.restaurant_rounded, color: Colors.white, size: 36),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nutrition Analyser', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('Type any food or ingredient to get full nutrition data', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search input
              SectionHeader(title: 'What did you eat?'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FitInput(
                      controller: _ctrl,
                      hint: 'e.g. 100g chicken breast',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () { HapticFeedback.mediumImpact(); _analyse(); },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF1B5E20)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF43A047).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick picks
              SectionHeader(title: 'Quick Picks'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickPicks.map((food) => GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _ctrl.text = food;
                    _analyse();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? kDarkCard : kLightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? kDarkBorder : kLightBorder),
                    ),
                    child: Text(food, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? kDarkText : kLightText)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),

              // Result
              if (_loading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF43A047)),
                ))
              else if (_error != null)
                FitCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: kError, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 13))),
                    ],
                  ),
                )
              else if (_result != null)
                _buildResult(_result!, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> data, bool isDark) {
    final calories  = (data['calories'] ?? 0).toDouble();
    final totalNutr = data['totalNutrients'] as Map<String, dynamic>? ?? {};

    double _g(String key) {
      final n = totalNutr[key];
      if (n == null) return 0;
      return ((n['quantity'] ?? 0) as num).toDouble();
    }

    final protein  = _g('PROCNT');
    final carbs    = _g('CHOCDF');
    final fat      = _g('FAT');
    final fiber    = _g('FIBTG');
    final sugar    = _g('SUGAR');
    final sodium   = _g('NA');
    final calcium  = _g('CA');
    final iron     = _g('FE');

    final label = data['ingredientLines'] is List
        ? (data['ingredientLines'] as List).join(', ')
        : _ctrl.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Results for "$label"'),
        const SizedBox(height: 16),

        // Calorie hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF1B5E20)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text('${calories.round()}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -2)),
              const SizedBox(width: 8),
              const Text('kcal', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Macro row
        Row(
          children: [
            _macroCard('Protein', protein, 'g', const Color(0xFF42A5F5)),
            const SizedBox(width: 10),
            _macroCard('Carbs', carbs, 'g', const Color(0xFFFF7043)),
            const SizedBox(width: 10),
            _macroCard('Fat', fat, 'g', const Color(0xFFAB47BC)),
          ],
        ),
        const SizedBox(height: 16),

        // Macro bar chart
        FitCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Macro Breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? kDarkText : kLightText)),
              const SizedBox(height: 14),
              _macroBar('Protein', protein, protein + carbs + fat, const Color(0xFF42A5F5), isDark),
              const SizedBox(height: 10),
              _macroBar('Carbs', carbs, protein + carbs + fat, const Color(0xFFFF7043), isDark),
              const SizedBox(height: 10),
              _macroBar('Fat', fat, protein + carbs + fat, const Color(0xFFAB47BC), isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Other nutrients
        SectionHeader(title: 'Other Nutrients'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            _nutrientTile('Fiber',   '${fiber.toStringAsFixed(1)}g',  Icons.grass_rounded,           const Color(0xFF4CAF50), isDark),
            _nutrientTile('Sugar',   '${sugar.toStringAsFixed(1)}g',  Icons.icecream_rounded,         const Color(0xFFFFCA28), isDark),
            _nutrientTile('Sodium',  '${sodium.toStringAsFixed(0)}mg',Icons.water_drop_rounded,       const Color(0xFF42A5F5), isDark),
            _nutrientTile('Calcium', '${calcium.toStringAsFixed(0)}mg',Icons.circle_rounded,          const Color(0xFFEF5350), isDark),
            _nutrientTile('Iron',    '${iron.toStringAsFixed(1)}mg',  Icons.bolt_rounded,             const Color(0xFFFF7043), isDark),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _macroCard(String label, double value, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: FitCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text('${value.toStringAsFixed(1)}$unit', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _macroBar(String label, double value, double total, Color color, bool isDark) {
    final pct = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? kDarkSubtext : kLightSubtext))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('${value.toStringAsFixed(1)}g', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? kDarkText : kLightText)),
      ],
    );
  }

  Widget _nutrientTile(String label, String value, IconData icon, Color color, bool isDark) {
    return FitCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? kDarkText : kLightText)),
                Text(label, style: TextStyle(fontSize: 10, color: isDark ? kDarkSubtext : kLightSubtext)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
