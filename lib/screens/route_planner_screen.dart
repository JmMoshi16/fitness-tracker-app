import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});
  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final _startLatCtrl = TextEditingController();
  final _startLngCtrl = TextEditingController();
  final _endLatCtrl   = TextEditingController();
  final _endLngCtrl   = TextEditingController();

  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;

  // Preset popular running spots (lat, lng)
  final _presets = [
    _Preset('Rizal Park, Manila',       '14.5831', '120.9794', '14.5876', '120.9822'),
    _Preset('BGC, Taguig',              '14.5547', '121.0509', '14.5490', '121.0560'),
    _Preset('UP Diliman Track',         '14.6540', '121.0650', '14.6580', '121.0700'),
    _Preset('Luneta to Intramuros',     '14.5831', '120.9794', '14.5895', '120.9750'),
    _Preset('Marikina River Park',      '14.6507', '121.1000', '14.6600', '121.1050'),
  ];

  @override
  void dispose() {
    _startLatCtrl.dispose(); _startLngCtrl.dispose();
    _endLatCtrl.dispose();   _endLngCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(_Preset p) {
    HapticFeedback.selectionClick();
    setState(() {
      _startLatCtrl.text = p.startLat;
      _startLngCtrl.text = p.startLng;
      _endLatCtrl.text   = p.endLat;
      _endLngCtrl.text   = p.endLng;
      _result = null; _error = null;
    });
  }

  Future<void> _findRoute() async {
    final sLat = _startLatCtrl.text.trim();
    final sLng = _startLngCtrl.text.trim();
    final eLat = _endLatCtrl.text.trim();
    final eLng = _endLngCtrl.text.trim();

    if (sLat.isEmpty || sLng.isEmpty || eLat.isEmpty || eLng.isEmpty) {
      setState(() => _error = 'Please fill in all coordinate fields.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final stops = '$sLat,$sLng;$eLat,$eLng';
      final data  = await ApiService.findRoute(stops);
      if (mounted) setState(() { _result = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not find route. Check coordinates and try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        title: const Text('Route Planner', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    colors: [Color(0xFF00897B), Color(0xFF004D40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF00897B).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.route_rounded, color: Colors.white, size: 36),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Run Route Planner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('Plan your outdoor run or cycling route', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick presets
              SectionHeader(title: 'Popular Running Spots'),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _presets.map((p) => GestureDetector(
                    onTap: () => _applyPreset(p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? kDarkCard : kLightCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? kDarkBorder : kLightBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_rounded, size: 14, color: Color(0xFF00897B)),
                          const SizedBox(width: 6),
                          Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? kDarkText : kLightText)),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Start coordinates
              SectionHeader(title: 'Start Point'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: FitInput(controller: _startLatCtrl, label: 'Latitude',  hint: '14.5831', keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), prefixIcon: Icons.my_location_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: FitInput(controller: _startLngCtrl, label: 'Longitude', hint: '120.9794', keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), prefixIcon: Icons.my_location_rounded)),
                ],
              ),
              const SizedBox(height: 20),

              // End coordinates
              SectionHeader(title: 'End Point'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: FitInput(controller: _endLatCtrl, label: 'Latitude',  hint: '14.5876', keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), prefixIcon: Icons.location_on_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: FitInput(controller: _endLngCtrl, label: 'Longitude', hint: '120.9822', keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), prefixIcon: Icons.location_on_rounded)),
                ],
              ),
              const SizedBox(height: 24),

              // Find route button
              FitButton(
                label: 'Find Route',
                icon: Icons.directions_run_rounded,
                isLoading: _loading,
                onTap: _findRoute,
                colors: const [Color(0xFF00897B), Color(0xFF004D40)],
              ),
              const SizedBox(height: 24),

              // Error
              if (_error != null)
                FitCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: kError, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 13))),
                    ],
                  ),
                ),

              // Result
              if (_result != null) _buildResult(_result!, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> data, bool isDark) {
    final route = data['route'] as Map<String, dynamic>? ?? {};
    final legs   = route['legs'] as List? ?? [];
    final distM  = (route['distance'] ?? 0).toDouble();   // metres
    final durS   = (route['duration'] ?? 0).toDouble();   // seconds
    final distKm = (distM / 1000).toStringAsFixed(2);
    final durMin = (durS / 60).round();

    // Collect all steps from all legs
    final steps = <Map<String, dynamic>>[];
    for (final leg in legs) {
      final legSteps = (leg as Map)['steps'] as List? ?? [];
      steps.addAll(legSteps.map((s) => Map<String, dynamic>.from(s as Map)));
    }

    // Estimate calories (running ~60 kcal/km, cycling ~30 kcal/km)
    final calRun  = (distM / 1000 * 60).round();
    final calCycle = (distM / 1000 * 30).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Route Summary'),
        const SizedBox(height: 12),

        // Summary cards
        Row(
          children: [
            _summaryCard('Distance', '$distKm km', Icons.straighten_rounded, const Color(0xFF00897B), isDark),
            const SizedBox(width: 12),
            _summaryCard('Duration', '$durMin min', Icons.timer_rounded, const Color(0xFF1976D2), isDark),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _summaryCard('Run Calories', '~$calRun kcal', Icons.directions_run_rounded, kOrange, isDark),
            const SizedBox(width: 12),
            _summaryCard('Cycle Calories', '~$calCycle kcal', Icons.directions_bike_rounded, const Color(0xFFAB47BC), isDark),
          ],
        ),
        const SizedBox(height: 24),

        if (steps.isNotEmpty) ...[
          SectionHeader(title: 'Turn-by-Turn Directions (${steps.length} steps)'),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final instruction = (step['instructions'] ?? step['description'] ?? 'Continue').toString();
            final stepDist = ((step['distance'] ?? 0) as num).toDouble();
            final stepDur  = ((step['duration'] ?? 0) as num).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FitCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF004D40)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(instruction, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? kDarkText : kLightText)),
                          if (stepDist > 0 || stepDur > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (stepDist > 0) ...[
                                  Icon(Icons.straighten_rounded, size: 12, color: isDark ? kDarkSubtext : kLightSubtext),
                                  const SizedBox(width: 4),
                                  Text('${(stepDist / 1000).toStringAsFixed(2)} km', style: TextStyle(fontSize: 11, color: isDark ? kDarkSubtext : kLightSubtext)),
                                  const SizedBox(width: 12),
                                ],
                                if (stepDur > 0) ...[
                                  Icon(Icons.timer_outlined, size: 12, color: isDark ? kDarkSubtext : kLightSubtext),
                                  const SizedBox(width: 4),
                                  Text('${(stepDur / 60).round()} min', style: TextStyle(fontSize: 11, color: isDark ? kDarkSubtext : kLightSubtext)),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: FitCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? kDarkText : kLightText)),
                  Text(label, style: TextStyle(fontSize: 10, color: isDark ? kDarkSubtext : kLightSubtext)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preset {
  final String name, startLat, startLng, endLat, endLng;
  const _Preset(this.name, this.startLat, this.startLng, this.endLat, this.endLng);
}
