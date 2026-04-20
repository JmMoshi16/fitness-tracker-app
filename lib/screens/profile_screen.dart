import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../db/db_helper.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/components.dart';

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
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
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
            content: const Text('Profile updated successfully', style: TextStyle(color: Colors.white)),
            backgroundColor: kSuccess,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kError),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kError, foregroundColor: Colors.white, elevation: 0),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? kDarkBg : kLightBg,
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Error Loading Profile',
          subtitle: _error!,
          actionLabel: 'Retry',
          onAction: _loadProfile,
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: isDark ? kDarkBg : kLightBg,
        body: const Center(child: CircularProgressIndicator(color: kOrange)),
      );
    }

    final totalMin = _workouts.fold(0, (s, w) => s + w.durationMinutes);
    final totalHours = (totalMin / 60).toStringAsFixed(1);
    final streak = _calcStreak();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? kDarkBg : kLightBg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: isDark ? kDarkSurface : kLightSurface,
              automaticallyImplyLeading: false,
              actions: [
                if (!_editing)
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_rounded, color: kOrange, size: 18),
                    ),
                    onPressed: () => setState(() => _editing = true),
                  )
                else
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.close_rounded, color: isDark ? kDarkText : kLightText, size: 18),
                    ),
                    onPressed: () {
                      _userCtrl.text = _user!.username;
                      _emailCtrl.text = _user!.email;
                      setState(() => _editing = false);
                    },
                  ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kOrange, kOrangeDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
                          ),
                          child: Center(
                            child: Text(
                              _user!.username.isNotEmpty ? _user!.username[0].toUpperCase() : 'A',
                              style: const TextStyle(color: kOrange, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(_user!.username, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_user!.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    Row(
                      children: [
                        StatTile(value: '${_workouts.length}', label: 'Workouts', icon: Icons.fitness_center_rounded, color: kOrange, isCompact: true),
                        const SizedBox(width: 12),
                        StatTile(value: totalHours, label: 'Hours', icon: Icons.timer_rounded, color: kInfo, isCompact: true),
                        const SizedBox(width: 12),
                        StatTile(value: '$streak', label: 'Streak', icon: Icons.local_fire_department_rounded, color: kError, isCompact: true),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Account Info Form
                    if (_editing) ...[
                      SectionHeader(title: 'Account Settings'),
                      const SizedBox(height: 16),
                      FitCard(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              FitInput(
                                controller: _userCtrl,
                                label: 'Username',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (v) => v!.trim().length < 3 ? 'Min 3 characters' : null,
                              ),
                              const SizedBox(height: 12),
                              FitInput(
                                controller: _emailCtrl,
                                label: 'Email Address',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => !v!.contains('@') ? 'Enter valid email' : null,
                              ),
                              const SizedBox(height: 16),
                              FitButton(
                                label: 'Save Changes',
                                icon: Icons.check_rounded,
                                onTap: _save,
                                isLoading: _saving,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // App Settings
                    SectionHeader(title: 'App Settings'),
                    const SizedBox(height: 16),
                    FitCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _buildSettingTile(
                            icon: Icons.dark_mode_rounded,
                            color: kOrange,
                            title: 'Dark Mode',
                            trailing: Switch(
                              value: themeProvider.isDark,
                              onChanged: (_) => themeProvider.toggle(),
                              activeColor: kOrange,
                            ),
                          ),
                          const Divider(height: 1),
                          _buildSettingTile(
                            icon: Icons.flag_rounded,
                            color: kSuccess,
                            title: 'Workout Goals',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              // Implement goal settings navigation
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingTile(
                            icon: Icons.download_rounded,
                            color: kInfo,
                            title: 'Export Data',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              // Navigate to data export
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Logout
                    FitButton(
                      label: 'Logout',
                      icon: Icons.logout_rounded,
                      onTap: _logout,
                      isSecondary: true,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required Color color, required String title, Widget? trailing, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(color: isDark ? kDarkText : kLightText, fontWeight: FontWeight.w600)),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: isDark ? kDarkSubtext : kLightSubtext),
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
}
