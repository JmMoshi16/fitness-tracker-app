import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);

class WorkoutTimerScreen extends StatefulWidget {
  const WorkoutTimerScreen({super.key});
  @override
  State<WorkoutTimerScreen> createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen> with TickerProviderStateMixin {
  final _audio = AudioPlayer();

  // Settings
  int _workSeconds = 30;
  int _restSeconds = 10;
  int _totalSets = 3;

  // State
  int _currentSet = 1;
  int _secondsLeft = 30;
  bool _isWork = true;
  bool _isRunning = false;
  bool _isDone = false;

  Timer? _timer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _workSeconds;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audio.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isDone = false;
      _currentSet = 1;
      _isWork = true;
      _secondsLeft = _workSeconds;
    });
  }

  Future<void> _playBeep({bool isEnd = false}) async {
    await _audio.play(AssetSource(isEnd ? 'sounds/finish.mp3' : 'sounds/beep.mp3'))
        .catchError((_) async {
      // fallback: system sound
      await _audio.play(AssetSource('sounds/beep.mp3')).catchError((_) {});
    });
  }

  void _tick() {
    if (_secondsLeft > 1) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 3) _playBeep();
    } else {
      // Phase ended
      if (_isWork) {
        // Work done → rest or next set
        if (_currentSet >= _totalSets) {
          // All sets done
          _timer?.cancel();
          _playBeep(isEnd: true);
          setState(() { _isRunning = false; _isDone = true; });
        } else {
          _playBeep();
          setState(() { _isWork = false; _secondsLeft = _restSeconds; });
        }
      } else {
        // Rest done → next set
        _playBeep();
        setState(() { _isWork = true; _currentSet++; _secondsLeft = _workSeconds; });
      }
    }
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final progress = _isWork
        ? 1 - (_secondsLeft / _workSeconds)
        : 1 - (_secondsLeft / _restSeconds);
    final phaseColor = _isWork ? kGreen : Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: kDeepDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () { _timer?.cancel(); Navigator.pop(context); },
        ),
        title: const Text('Workout Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_isRunning && !_isDone && _currentSet == 1) ...[
              // ── Settings ──────────────────────────────────────────────────
              _settingsCard(),
              const SizedBox(height: 24),
            ],

            // ── Timer circle ──────────────────────────────────────────────
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isDone)
                        const Icon(Icons.emoji_events_rounded, color: kGreen, size: 56)
                      else ...[
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Text(
                            _fmt(_secondsLeft),
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: _isRunning
                                  ? Color.lerp(phaseColor, kDeepDark, _pulseCtrl.value)!
                                  : kDeepDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: phaseColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isWork ? 'WORK' : 'REST',
                            style: TextStyle(color: phaseColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Set indicators ────────────────────────────────────────────
            if (!_isDone) ...[
              Text('Set $_currentSet of $_totalSets',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDeepDark)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalSets, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 32,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < _currentSet - 1
                        ? kGreen
                        : i == _currentSet - 1
                            ? phaseColor
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ] else ...[
              const Text('🎉 Workout Complete!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kDeepDark)),
              const SizedBox(height: 6),
              Text('$_totalSets sets finished',
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],

            const SizedBox(height: 32),

            // ── Controls ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _controlBtn(Icons.refresh_rounded, Colors.grey, _reset),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _isDone ? _reset : (_isRunning ? _pause : _start),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [phaseColor, phaseColor.withOpacity(0.7)]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: phaseColor.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Icon(
                      _isDone ? Icons.replay_rounded : (_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _controlBtn(Icons.skip_next_rounded, kDeepDark, () {
                  if (!_isDone) { _timer?.cancel(); setState(() { _isRunning = false; }); _tick(); _tick(); }
                }),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _controlBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      );

  Widget _settingsCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timer Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDeepDark)),
            const SizedBox(height: 16),
            _sliderRow('Work Time', _workSeconds, 10, 120, kGreen, (v) => setState(() { _workSeconds = v; _secondsLeft = v; })),
            _sliderRow('Rest Time', _restSeconds, 5, 60, Colors.orange, (v) => setState(() => _restSeconds = v)),
            _sliderRow('Sets', _totalSets, 1, 10, kDeepDark, (v) => setState(() => _totalSets = v)),
          ],
        ),
      );

  Widget _sliderRow(String label, int value, int min, int max, Color color, ValueChanged<int> onChanged) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                activeColor: color,
                inactiveColor: color.withOpacity(0.2),
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                label == 'Sets' ? '$value' : _fmt(value),
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
              ),
            ),
          ],
        ),
      );
}
