import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);

class RestTimerScreen extends StatefulWidget {
  const RestTimerScreen({super.key});
  @override
  State<RestTimerScreen> createState() => _RestTimerScreenState();
}

class _RestTimerScreenState extends State<RestTimerScreen>
    with SingleTickerProviderStateMixin {
  int _selectedSeconds = 90;
  int _remaining = 90;
  bool _running = false;
  Timer? _timer;
  late AnimationController _pulseCtrl;

  final _presets = [30, 60, 90, 120, 180, 300];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _initNotifications();
  }

  Future<void> _initNotifications() async {}

  void _start() {
    setState(() { _running = true; _remaining = _selectedSeconds; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
        setState(() => _running = false);
        _showDoneNotification();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() { _running = false; _remaining = _selectedSeconds; });
  }

  Future<void> _showDoneNotification() async {
    SystemSound.play(SystemSoundType.alert);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.fitness_center_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Rest complete! Time to lift!'),
          ]),
          backgroundColor: kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  double get _progress =>
      _selectedSeconds == 0 ? 0 : (_remaining / _selectedSeconds);

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
        title: const Text('Rest Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Circular timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _remaining <= 10 ? Colors.red : kGreen,
                      ),
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Opacity(
                          opacity: _running ? (0.6 + _pulseCtrl.value * 0.4) : 1.0,
                          child: Text(
                            _fmt(_remaining),
                            style: TextStyle(
                              color: _remaining <= 10 ? Colors.red : Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        _running ? 'Resting...' : (_remaining == _selectedSeconds ? 'Ready' : 'Paused'),
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Preset buttons
              const Text('Quick Select', style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _presets.map((s) {
                  final selected = _selectedSeconds == s;
                  return GestureDetector(
                    onTap: () {
                      if (!_running) {
                        setState(() { _selectedSeconds = s; _remaining = s; });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? kGreen : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? kGreen : Colors.white12),
                      ),
                      child: Text(
                        s >= 60 ? '${s ~/ 60}m${s % 60 > 0 ? ' ${s % 60}s' : ''}' : '${s}s',
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 24),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Play/Pause
                  GestureDetector(
                    onTap: _running ? _pause : _start,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kGreen, kDarkGreen]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: kGreen.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: Icon(
                        _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Skip
                  GestureDetector(
                    onTap: () { _timer?.cancel(); setState(() { _running = false; _remaining = 0; }); },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: Colors.white38, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You will receive a notification when rest is complete, even if the app is in background.',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
