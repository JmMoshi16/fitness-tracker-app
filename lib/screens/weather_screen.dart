import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _ctrl = TextEditingController(text: 'Manila');
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final city = _ctrl.text.trim();
    if (city.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; _data = null; });
    try {
      final data = await ApiService.fetchWeather(city);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'City not found. Try another name.'; _loading = false; });
    }
  }

  // Map weather condition to workout suggestion
  _WorkoutSuggestion _getSuggestion(String condition, double temp) {
    final c = condition.toLowerCase();
    if (c.contains('rain') || c.contains('drizzle') || c.contains('thunderstorm')) {
      return _WorkoutSuggestion(
        icon: Icons.fitness_center_rounded,
        title: 'Indoor Workout Day',
        subtitle: 'Rain outside — perfect for strength training or yoga indoors.',
        color: const Color(0xFF42A5F5),
        workouts: ['Strength Training', 'Yoga', 'HIIT', 'Stretching'],
      );
    }
    if (temp > 35) {
      return _WorkoutSuggestion(
        icon: Icons.pool_rounded,
        title: 'Stay Cool',
        subtitle: 'Very hot outside — try swimming or early morning runs.',
        color: const Color(0xFFEF5350),
        workouts: ['Swimming', 'Early Morning Run', 'Indoor Cycling'],
      );
    }
    if (temp < 10) {
      return _WorkoutSuggestion(
        icon: Icons.ac_unit_rounded,
        title: 'Cold Weather Training',
        subtitle: 'Cold outside — warm up well before any outdoor activity.',
        color: const Color(0xFF26C6DA),
        workouts: ['Indoor Cardio', 'Strength Training', 'Hot Yoga'],
      );
    }
    if (c.contains('clear') || c.contains('sun')) {
      return _WorkoutSuggestion(
        icon: Icons.directions_run_rounded,
        title: 'Perfect Outdoor Day!',
        subtitle: 'Great weather for outdoor workouts. Get outside!',
        color: const Color(0xFF4CAF50),
        workouts: ['Running', 'Cycling', 'Outdoor HIIT', 'Sports'],
      );
    }
    return _WorkoutSuggestion(
      icon: Icons.sports_gymnastics_rounded,
      title: 'Good Training Conditions',
      subtitle: 'Decent weather — mix of indoor and outdoor works well.',
      color: kOrange,
      workouts: ['Running', 'Strength Training', 'Cycling'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        title: const Text('Workout Weather', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetch,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Row(
                children: [
                  Expanded(
                    child: FitInput(
                      controller: _ctrl,
                      hint: 'Enter city name...',
                      prefixIcon: Icons.location_on_rounded,
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () { HapticFeedback.mediumImpact(); _fetch(); },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_loading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                ))
              else if (_error != null)
                FitCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: kError, size: 28),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_error!, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext))),
                    ],
                  ),
                )
              else if (_data != null)
                _buildWeatherContent(_data!, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherContent(Map<String, dynamic> d, bool isDark) {
    final main      = d['main'] as Map<String, dynamic>? ?? {};
    final weather   = (d['weather'] as List?)?.first as Map<String, dynamic>? ?? {};
    final wind      = d['wind'] as Map<String, dynamic>? ?? {};
    final cityName  = d['name'] ?? '';
    final country   = (d['sys'] as Map?)? ['country'] ?? '';
    final temp      = (main['temp'] ?? 0).toDouble();
    final feelsLike = (main['feels_like'] ?? 0).toDouble();
    final humidity  = main['humidity'] ?? 0;
    final windSpeed = (wind['speed'] ?? 0).toDouble();
    final condition = weather['main'] ?? 'Clear';
    final desc      = weather['description'] ?? '';

    final suggestion = _getSuggestion(condition, temp);
    final bgColors   = _bgColors(condition, temp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main weather card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: bgColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: bgColors[0].withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$cityName, $country', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${temp.round()}°C', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -2)),
                      Text(_capitalize(desc), style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Text(_weatherEmoji(condition), style: const TextStyle(fontSize: 72)),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _weatherStat('Feels Like', '${feelsLike.round()}°C', Icons.thermostat_rounded),
                  _weatherStat('Humidity', '$humidity%', Icons.water_drop_rounded),
                  _weatherStat('Wind', '${windSpeed.toStringAsFixed(1)} m/s', Icons.air_rounded),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Workout suggestion card
        FitCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: suggestion.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                    child: Icon(suggestion.icon, color: suggestion.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(suggestion.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? kDarkText : kLightText)),
                        const SizedBox(height: 4),
                        Text(suggestion.subtitle, style: TextStyle(color: isDark ? kDarkSubtext : kLightSubtext, fontSize: 12, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Recommended Workouts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? kDarkSubtext : kLightSubtext)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestion.workouts.map((w) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: suggestion.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: suggestion.color.withOpacity(0.3)),
                  ),
                  child: Text(w, style: TextStyle(color: suggestion.color, fontSize: 12, fontWeight: FontWeight.w700)),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Extra stats row
        Row(
          children: [
            Expanded(child: _statMiniCard('Humidity', '$humidity%', Icons.water_drop_rounded, const Color(0xFF42A5F5), isDark)),
            const SizedBox(width: 12),
            Expanded(child: _statMiniCard('Wind Speed', '${windSpeed.toStringAsFixed(1)} m/s', Icons.air_rounded, const Color(0xFF26C6DA), isDark)),
          ],
        ),
      ],
    );
  }

  Widget _weatherStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _statMiniCard(String label, String value, IconData icon, Color color, bool isDark) {
    return FitCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? kDarkText : kLightText)),
              Text(label, style: TextStyle(fontSize: 10, color: isDark ? kDarkSubtext : kLightSubtext)),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _bgColors(String condition, double temp) {
    final c = condition.toLowerCase();
    if (c.contains('rain') || c.contains('drizzle')) return [const Color(0xFF1565C0), const Color(0xFF0D47A1)];
    if (c.contains('thunder')) return [const Color(0xFF4A148C), const Color(0xFF1A237E)];
    if (c.contains('snow')) return [const Color(0xFF0288D1), const Color(0xFF01579B)];
    if (c.contains('cloud')) return [const Color(0xFF546E7A), const Color(0xFF37474F)];
    if (temp > 35) return [const Color(0xFFE53935), const Color(0xFFB71C1C)];
    return [const Color(0xFF1976D2), const Color(0xFF0D47A1)];
  }

  String _weatherEmoji(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('thunder')) return '⛈️';
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('snow')) return '❄️';
    if (c.contains('cloud')) return '☁️';
    if (c.contains('mist') || c.contains('fog')) return '🌫️';
    return '☀️';
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _WorkoutSuggestion {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<String> workouts;
  const _WorkoutSuggestion({required this.icon, required this.title, required this.subtitle, required this.color, required this.workouts});
}
