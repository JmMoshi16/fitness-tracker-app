import 'package:flutter/material.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);

class PlateCalculatorScreen extends StatefulWidget {
  const PlateCalculatorScreen({super.key});
  @override
  State<PlateCalculatorScreen> createState() => _PlateCalculatorScreenState();
}

class _PlateCalculatorScreenState extends State<PlateCalculatorScreen> {
  final _ctrl = TextEditingController();
  double _barWeight = 20; // standard olympic bar
  List<Map<String, dynamic>> _plates = [];
  String? _error;

  // Available plate weights (kg)
  final _availablePlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

  final _plateColors = {
    25.0: const Color(0xFFEF5350),
    20.0: const Color(0xFF42A5F5),
    15.0: const Color(0xFFFFEE58),
    10.0: const Color(0xFF66BB6A),
    5.0: const Color(0xFFFFFFFF),
    2.5: const Color(0xFF78909C),
    1.25: const Color(0xFFFFCC02),
  };

  void _calculate() {
    final input = double.tryParse(_ctrl.text.trim());
    if (input == null || input <= 0) {
      setState(() { _error = 'Enter a valid weight'; _plates = []; });
      return;
    }
    if (input <= _barWeight) {
      setState(() { _error = 'Weight must be greater than bar (${_barWeight}kg)'; _plates = []; });
      return;
    }

    setState(() => _error = null);

    double remaining = (input - _barWeight) / 2; // per side
    final result = <Map<String, dynamic>>[];

    for (final plate in _availablePlates) {
      final count = (remaining / plate).floor();
      if (count > 0) {
        result.add({'weight': plate, 'count': count});
        remaining -= count * plate;
        remaining = double.parse(remaining.toStringAsFixed(4));
      }
    }

    setState(() => _plates = result);
  }

  double get _totalPerSide => _plates.fold(0.0, (s, p) => s + p['weight'] * p['count']);
  double get _totalWeight => _barWeight + (_totalPerSide * 2);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
        title: const Text('Plate Calculator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bar weight selector
              const Text('Bar Weight', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [15.0, 20.0, 25.0].map((b) {
                  final selected = _barWeight == b;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _barWeight = b),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? kGreen : Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? kGreen : Colors.white12),
                        ),
                        child: Text('${b.toInt()}kg',
                            style: TextStyle(color: selected ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Target weight input
              const Text('Target Weight (kg)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 100',
                          hintStyle: TextStyle(color: Colors.white24),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          suffixText: 'kg',
                          suffixStyle: TextStyle(color: Colors.white38),
                        ),
                        onSubmitted: (_) => _calculate(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _calculate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kGreen, kDarkGreen]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: kGreen.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],

              if (_plates.isNotEmpty) ...[
                const SizedBox(height: 28),

                // Result summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _resultStat('${_totalWeight}kg', 'Total Weight'),
                      _vDivider(),
                      _resultStat('${_barWeight}kg', 'Bar'),
                      _vDivider(),
                      _resultStat('${_totalPerSide}kg', 'Per Side'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bar visualization
                const Text('Per Side', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildBarVisualization(),
                const SizedBox(height: 24),

                // Plate list
                const Text('Plates Per Side', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ..._plates.map((p) => _plateTile(p['weight'], p['count'])),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarVisualization() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bar end
          Container(width: 20, height: 12, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(4))),
          // Plates
          ..._plates.expand((p) => List.generate(p['count'] as int, (_) => _plateVisual(p['weight']))),
          // Bar center
          Container(width: 60, height: 8, color: Colors.grey.shade500),
          const Text('...', style: TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _plateVisual(double weight) {
    final color = _plateColors[weight] ?? Colors.grey;
    final height = weight >= 20 ? 52.0 : weight >= 10 ? 44.0 : weight >= 5 ? 36.0 : 28.0;
    return Container(
      width: 14,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black26, width: 0.5),
      ),
    );
  }

  Widget _plateTile(double weight, int count) {
    final color = _plateColors[weight] ?? Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('${weight}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('${weight}kg plate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text('x$count', style: const TextStyle(color: kGreen, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _resultStat(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      );

  Widget _vDivider() => Container(width: 1, height: 32, color: Colors.white12);
}
