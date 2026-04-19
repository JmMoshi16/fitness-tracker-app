import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/db_helper.dart';
import '../models/models.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;
  const ProfileScreen({super.key, this.onDataChanged});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  UserModel? _user;
  List<Workout> _workouts = [];
  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _error = null);
    try {
      final firebaseUser = await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null, orElse: () => null);

      if (firebaseUser == null) {
        // Fallback: load from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final username = prefs.getString('username') ?? 'User';
        final email = prefs.getString('email') ?? '';
        if (mounted) {
          setState(() {
            _user = UserModel(uid: '', username: username, email: email);
            _workouts = [];
            _userCtrl.text = username;
            _emailCtrl.text = email;
          });
        }
        return;
      }

      final user = await DBHelper.getCurrentUser();
      final workouts = user != null ? await DBHelper.getWorkouts(firebaseUser.uid) : <Workout>[];
      if (mounted) {
        if (user == null) {
          // Fallback to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final username = prefs.getString('username') ?? 'User';
          final email = prefs.getString('email') ?? firebaseUser.email ?? '';
          setState(() {
            _user = UserModel(uid: firebaseUser.uid, username: username, email: email);
            _workouts = [];
            _userCtrl.text = username;
            _emailCtrl.text = email;
          });
          return;
        }
        setState(() {
          _user = user;
          _workouts = workouts;
          _userCtrl.text = user.username;
          _emailCtrl.text = user.email;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load profile: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      _user!.username = _userCtrl.text.trim();
      _user!.email = _emailCtrl.text.trim();
      await DBHelper.updateUser(_user!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _user!.username);
      widget.onDataChanged?.call();
      if (mounted) {
        setState(() { _editing = false; _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Profile updated successfully'),
            ]),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await DBHelper.logoutUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6F9),
        body: Center(child: CircularProgressIndicator(color: kGreen)),
      );
    }

    final totalMin = _workouts.fold(0, (s, w) => s + w.durationMinutes);
    final totalHours = (totalMin / 60).toStringAsFixed(1);
    final streak = _calcStreak();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: CustomScrollView(
          slivers: [
            // ── App bar / hero ──────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: kDeepDark,
              automaticallyImplyLeading: false,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              actions: [
                if (!_editing)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    ),
                    onPressed: () => setState(() => _editing = true),
                  )
                else
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                    onPressed: () {
                      _userCtrl.text = _user!.username;
                      _emailCtrl.text = _user!.email;
                      setState(() => _editing = false);
                    },
                  ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                  ),
                  onPressed: _logout,
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kDeepDark, Color(0xFF16213E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),
                        // Avatar
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [kGreen, kDarkGreen]),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: kGreen.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
                          ),
                          child: Center(
                            child: Text(
                              _user!.username.isNotEmpty ? _user!.username[0].toUpperCase() : 'A',
                              style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(_user!.username,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.email_outlined, color: Colors.white38, size: 13),
                            const SizedBox(width: 4),
                            Text(_user!.email, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: kGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kGreen.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: kGreen, size: 14),
                              const SizedBox(width: 5),
                              Text('$streak day streak', style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ── Stats row ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: _statCard('${_workouts.length}', 'Workouts', Icons.fitness_center_rounded, kGreen)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard(totalHours, 'Hours', Icons.timer_rounded, Colors.orange)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard('$streak', 'Day Streak', Icons.local_fire_department_rounded, Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Account info ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _sectionCard(
                      title: 'Account Info',
                      icon: Icons.manage_accounts_rounded,
                      iconColor: kGreen,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _profileField(
                              controller: _userCtrl,
                              label: 'Username',
                              icon: Icons.person_outline_rounded,
                              enabled: _editing,
                              validator: (v) => v!.trim().length < 3 ? 'Min 3 characters' : null,
                            ),
                            Divider(height: 1, color: Colors.grey.shade100),
                            _profileField(
                              controller: _emailCtrl,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              enabled: _editing,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => !v!.contains('@') ? 'Enter valid email' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_editing) ...[
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Workout type breakdown ────────────────────────────────
                  if (_workouts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _sectionCard(
                        title: 'Activity Breakdown',
                        icon: Icons.pie_chart_rounded,
                        iconColor: Colors.purple,
                        child: Column(children: _buildBreakdown()),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Recent workouts ───────────────────────────────────────
                  if (_workouts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _sectionCard(
                        title: 'Recent Activity',
                        icon: Icons.history_rounded,
                        iconColor: Colors.orange,
                        child: Column(
                          children: _workouts.take(5).map((w) => _recentTile(w)).toList(),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calcStreak() {
    if (_workouts.isEmpty) return 0;
    final dates = _workouts.map((w) => w.date).toSet().toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime check = DateTime.now();
    for (final d in dates) {
      final day = DateTime.parse(d);
      final diff = check.difference(day).inDays;
      if (diff <= 1) {
        streak++;
        check = day;
      } else {
        break;
      }
    }
    return streak;
  }

  List<Widget> _buildBreakdown() {
    final types = ['Cardio', 'Strength', 'Flexibility', 'HIIT', 'Sports', 'Other'];
    final colors = [const Color(0xFFEF5350), const Color(0xFF42A5F5), const Color(0xFF66BB6A),
                    const Color(0xFFFF7043), const Color(0xFFAB47BC), const Color(0xFF78909C)];
    final total = _workouts.length;
    return types.asMap().entries.where((e) {
      return _workouts.any((w) => w.type == e.value);
    }).map((e) {
      final count = _workouts.where((w) => w.type == e.value).length;
      final ratio = count / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('$count sessions · ${(ratio * 100).round()}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: colors[e.key].withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(colors[e.key]),
                minHeight: 7,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _statCard(String value, String label, IconData icon, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDeepDark)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _sectionCard({required String title, required IconData icon, required Color iconColor, required Widget child}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kDeepDark)),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      );

  Widget _recentTile(Workout w) {
    final colors = {
      'Cardio': const Color(0xFFEF5350), 'Strength': const Color(0xFF42A5F5),
      'Flexibility': const Color(0xFF66BB6A), 'HIIT': const Color(0xFFFF7043),
      'Sports': const Color(0xFFAB47BC),
    };
    final color = colors[w.type] ?? const Color(0xFF78909C);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon(w.type), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kDeepDark)),
                Text('${w.type} · ${w.durationMinutes} min', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(w.date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Cardio': return Icons.directions_run_rounded;
      case 'Strength': return Icons.fitness_center_rounded;
      case 'Flexibility': return Icons.self_improvement_rounded;
      case 'HIIT': return Icons.flash_on_rounded;
      case 'Sports': return Icons.sports_rounded;
      default: return Icons.sports_gymnastics_rounded;
    }
  }

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500, color: kDeepDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: enabled ? kGreen : Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: enabled ? kGreen : Colors.grey.shade400, size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        disabledBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: enabled,
        fillColor: enabled ? kGreen.withOpacity(0.04) : null,
      ),
      validator: validator,
    );
  }
}
