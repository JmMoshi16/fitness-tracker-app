import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

// ── Notification helper (init once) ─────────────────────────────────────────
final _notif = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _notif.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
}

Future<void> _showStepNotification(int steps, int goal) async {
  const android = AndroidNotificationDetails(
    'steps_channel', 'Step Counter',
    channelDescription: 'Daily step progress',
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    showProgress: true,
    maxProgress: 100,
    progress: 0,
    icon: '@mipmap/ic_launcher',
  );
  final pct = ((steps / goal) * 100).clamp(0, 100).toInt();
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      'steps_channel', 'Step Counter',
      channelDescription: 'Daily step progress',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showProgress: true,
      maxProgress: 100,
      progress: pct,
      icon: '@mipmap/ic_launcher',
    ),
  );
  await _notif.show(
    1,
    '🚶 $steps / $goal steps',
    pct >= 100 ? '🎉 Daily goal reached!' : '${100 - pct}% to your goal',
    details,
  );
}

// ── Screen ───────────────────────────────────────────────────────────────────
class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});
  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  // Pedometer
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  int _steps = 0;
  int _stepsAtDayStart = 0;
  String _status = 'stopped';
  bool _permissionDenied = false;

  // Goal
  int _goal = 10000;
  final _goalCtrl = TextEditingController();

  // History (from Firestore)
  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = true;

  // Today's date key
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadGoal();
    _loadHistory();
    _initPedometer();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('step_goal') ?? 10000;
    if (mounted) setState(() { _goal = saved; _goalCtrl.text = saved.toString(); });
  }

  Future<void> _saveGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('step_goal', goal);
    setState(() => _goal = goal);
  }

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    // Load today's saved step offset from prefs
    final prefs = await SharedPreferences.getInstance();
    _stepsAtDayStart = prefs.getInt('steps_at_day_start_$_todayKey') ?? -1;

    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (e) { if (mounted) setState(() => _status = e.status); },
      onError: (_) { if (mounted) setState(() => _status = 'unavailable'); },
    );

    _stepSub = Pedometer.stepCountStream.listen(
      (e) async {
        // First reading of the day — save as baseline
        if (_stepsAtDayStart == -1) {
          _stepsAtDayStart = e.steps;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('steps_at_day_start_$_todayKey', _stepsAtDayStart);
        }
        final todaySteps = e.steps - _stepsAtDayStart;
        if (mounted) setState(() => _steps = todaySteps.clamp(0, 999999));

        // Persist to Firestore
        _persistSteps(todaySteps);

        // Update persistent notification
        await _showStepNotification(_steps, _goal);

        // Milestone notifications
        _checkMilestones(_steps);
      },
      onError: (_) { if (mounted) setState(() => _status = 'unavailable'); },
    );
  }

  Future<void> _persistSteps(int steps) async {
    final uid = DBHelper.currentUid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('step_logs')
        .doc('${uid}_$_todayKey')
        .set({'userId': uid, 'date': _todayKey, 'steps': steps, 'goal': _goal, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<void> _loadHistory() async {
    final uid = DBHelper.currentUid;
    if (uid == null) { if (mounted) setState(() => _loadingHistory = false); return; }
    final snap = await FirebaseFirestore.instance
        .collection('step_logs')
        .where('userId', isEqualTo: uid)
        .limit(14)
        .get();
    if (mounted) {
      setState(() {
        _history = snap.docs.map((d) => d.data()).toList();
        _history.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
        _loadingHistory = false;
      });
    }
  }

  void _checkMilestones(int steps) async {
    final milestones = [2500, 5000, 7500, 10000];
    for (final m in milestones) {
      if (steps == m) {
        await _notif.show(
          m,
          '🏆 Milestone reached!',
          'You hit $m steps today! Keep going!',
          const NotificationDetails(
            android: AndroidNotificationDetails('milestone_channel', 'Milestones', channelDescription: 'Step milestones', importance: Importance.high, priority: Priority.high),
          ),
        );
      }
    }
  }

  void _showGoalDialog() {
    _goalCtrl.text = _goal.toString();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? kDarkSurface : kLightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set Daily Step Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? kDarkText : kLightText)),
                const SizedBox(height: 16),
                // Quick presets
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [5000, 7500, 10000, 12500, 15000].map((g) => GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); _goalCtrl.text = g.toString(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _goal == g ? kOrange : (isDark ? kDarkCard : kLightCard),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _goal == g ? kOrange : (isDark ? kDarkBorder : kLightBorder)),
                      ),
                      child: Text('${(g / 1000).toStringAsFixed(1)}k', style: TextStyle(color: _goal == g ? Colors.white : (isDark ? kDarkText : kLightText), fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                FitInput(controller: _goalCtrl, label: 'Custom Goal', hint: '10000', keyboardType: TextInputType.number, prefixIcon: Icons.flag_rounded),
                const SizedBox(height: 20),
                FitButton(
                  label: 'Save Goal',
                  icon: Icons.check_rounded,
                  onTap: () {
                    final val = int.tryParse(_goalCtrl.text.trim());
                    if (val != null && val > 0) {
                      _saveGoal(val);
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_steps / _goal).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    final distKm = (_steps * 0.000762).toStringAsFixed(2); // avg stride 76.2cm
    final calories = (_steps * 0.04).round(); // ~0.04 kcal/step

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        title: const Text('Step Counter', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.flag_rounded, color: kOrange), onPressed: _showGoalDialog),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadHistory),
        ],
      ),
      body: SafeArea(
        child: _permissionDenied
            ? _buildPermissionDenied(isDark)
            : RefreshIndicator(
                onRefresh: _loadHistory,
                color: kOrange,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Main ring card
                      _buildRingCard(progress, pct, isDark),
                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        children: [
                          _statCard('Distance', '$distKm km', Icons.straighten_rounded, kInfo, isDark),
                          const SizedBox(width: 12),
                          _statCard('Calories', '$calories kcal', Icons.local_fire_department_rounded, kError, isDark),
                          const SizedBox(width: 12),
                          _statCard('Status', _status == 'walking' ? 'Walking' : _status == 'stopped' ? 'Still' : 'N/A',
                              _status == 'walking' ? Icons.directions_walk_rounded : Icons.accessibility_new_rounded,
                              _status == 'walking' ? const Color(0xFF4CAF50) : kOrange, isDark),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Goal progress bar
                      FitCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Daily Goal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? kDarkText : kLightText)),
                                GestureDetector(
                                  onTap: _showGoalDialog,
                                  child: Row(children: [
                                    Text('$_goal steps', style: const TextStyle(color: kOrange, fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_rounded, color: kOrange, size: 14),
                                  ]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: kOrange.withOpacity(0.12),
                                valueColor: const AlwaysStoppedAnimation<Color>(kOrange),
                                minHeight: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$_steps steps', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12)),
                                Text('$pct% complete', style: const TextStyle(color: kOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Milestones
                      SectionHeader(title: 'Milestones'),
                      const SizedBox(height: 12),
                      _buildMilestones(isDark),
                      const SizedBox(height: 24),

                      // 14-day history
                      SectionHeader(title: '14-Day History'),
                      const SizedBox(height: 12),
                      _loadingHistory
                          ? const Center(child: CircularProgressIndicator(color: kOrange))
                          : _history.isEmpty
                              ? EmptyState(icon: Icons.directions_walk_rounded, title: 'No history yet', subtitle: 'Start walking to record your steps')
                              : _buildHistory(isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRingCard(double progress, int pct, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kOrange, kOrangeDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: kOrange.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_walk_rounded, color: Colors.white70, size: 28),
                  const SizedBox(height: 4),
                  Text('$_steps', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  Text('of $_goal steps', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            pct >= 100 ? '🎉 Goal Reached! Amazing!' : pct >= 75 ? '💪 Almost there! Keep going!' : pct >= 50 ? '🔥 Halfway there!' : '👟 Keep walking!',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones(bool isDark) {
    final milestones = [
      {'steps': 2500, 'label': '2.5k', 'icon': '🥉'},
      {'steps': 5000, 'label': '5k',   'icon': '🥈'},
      {'steps': 7500, 'label': '7.5k', 'icon': '🥇'},
      {'steps': 10000,'label': '10k',  'icon': '🏆'},
    ];
    return Row(
      children: milestones.map((m) {
        final reached = _steps >= (m['steps'] as int);
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: reached ? kOrange.withOpacity(0.12) : (isDark ? kDarkCard : kLightCard),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: reached ? kOrange.withOpacity(0.4) : (isDark ? kDarkBorder : kLightBorder)),
            ),
            child: Column(
              children: [
                Text(m['icon'] as String, style: TextStyle(fontSize: 22, color: reached ? null : const Color(0x44000000))),
                const SizedBox(height: 4),
                Text(m['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: reached ? kOrange : (isDark ? kDarkSubtext : kLightSubtext))),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistory(bool isDark) {
    return Column(
      children: _history.map((d) {
        final steps = d['steps'] as int? ?? 0;
        final goal  = d['goal']  as int? ?? 10000;
        final date  = d['date']  as String? ?? '';
        final pct   = (steps / goal).clamp(0.0, 1.0);
        final reached = steps >= goal;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FitCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: reached ? kOrange.withOpacity(0.12) : (isDark ? kDarkSurface : kLightSurface),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(reached ? Icons.check_circle_rounded : Icons.directions_walk_rounded,
                      color: reached ? kOrange : (isDark ? kDarkSubtext : kLightSubtext), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? kDarkText : kLightText)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: kOrange.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(reached ? kOrange : kInfo),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$steps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? kDarkText : kLightText)),
                    Text('steps', style: TextStyle(fontSize: 10, color: isDark ? kDarkSubtext : kLightSubtext)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: FitCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? kDarkText : kLightText), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: TextStyle(fontSize: 9, color: isDark ? kDarkSubtext : kLightSubtext)),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_walk_rounded, size: 64, color: kOrange),
            const SizedBox(height: 16),
            Text('Activity Permission Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? kDarkText : kLightText)),
            const SizedBox(height: 8),
            Text('Please grant activity recognition permission to count your steps.', style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FitButton(label: 'Open Settings', icon: Icons.settings_rounded, onTap: () => openAppSettings()),
          ],
        ),
      ),
    );
  }
}
