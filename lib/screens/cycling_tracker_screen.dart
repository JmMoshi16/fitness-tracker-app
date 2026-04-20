import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/models.dart';
import '../services/api_service.dart';

const kGreen = Color(0xFF8BC34A);
const kDarkGreen = Color(0xFF558B2F);
const kDeepDark = Color(0xFF1A1A2E);
const kCardDark = Color(0xFF16213E);

class CyclingTrackerScreen extends StatefulWidget {
  const CyclingTrackerScreen({super.key});
  @override
  State<CyclingTrackerScreen> createState() => _CyclingTrackerScreenState();
}

class _CyclingTrackerScreenState extends State<CyclingTrackerScreen> {
  bool _tracking = false;
  bool _saving = false;
  double _distanceKm = 0;
  double _currentSpeedKmh = 0;
  double _maxSpeedKmh = 0;
  double _avgSpeedKmh = 0;
  int _elapsedSeconds = 0;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  List<double> _speedReadings = [];
  List<CyclingSession> _sessions = [];
  bool _loadingSessions = true;

  // Weather
  Map<String, dynamic>? _weather;
  bool _loadingWeather = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _loadWeather();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    setState(() => _loadingWeather = true);
    try {
      // Get current position for accurate weather
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 5), onTimeout: () =>
        Position.fromMap({'latitude': 14.5995, 'longitude': 120.9842, 'timestamp': DateTime.now().millisecondsSinceEpoch, 'accuracy': 0.0, 'altitude': 0.0, 'heading': 0.0, 'speed': 0.0, 'speedAccuracy': 0.0, 'altitudeAccuracy': 0.0, 'headingAccuracy': 0.0}),
      );
      final data = await ApiService.fetchCyclingWeather(pos.latitude, pos.longitude);
      if (mounted) setState(() { _weather = data; _loadingWeather = false; });
    } catch (_) {
      // Fallback to Manila coords
      try {
        final data = await ApiService.fetchCyclingWeather(14.5995, 120.9842);
        if (mounted) setState(() { _weather = data; _loadingWeather = false; });
      } catch (_) {
        if (mounted) setState(() => _loadingWeather = false);
      }
    }
  }

  Future<void> _loadSessions() async {
    final uid = DBHelper.currentUid;
    if (uid == null) return;
    final list = await DBHelper.getCyclingSessions(uid);
    if (mounted) setState(() { _sessions = list; _loadingSessions = false; });
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enable location services'),
          backgroundColor: Colors.orange,
        ));
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> _startTracking() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) return;

    setState(() {
      _tracking = true;
      _distanceKm = 0;
      _currentSpeedKmh = 0;
      _maxSpeedKmh = 0;
      _avgSpeedKmh = 0;
      _elapsedSeconds = 0;
      _lastPosition = null;
      _speedReadings = [];
    });

    // Start elapsed timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    // Start GPS tracking
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5 meters
      ),
    ).listen((pos) {
      if (_lastPosition != null) {
        final dist = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          pos.latitude, pos.longitude,
        );
        final speedKmh = (pos.speed * 3.6).clamp(0.0, 200.0);

        setState(() {
          _distanceKm += dist / 1000;
          _currentSpeedKmh = speedKmh;
          if (speedKmh > _maxSpeedKmh) _maxSpeedKmh = speedKmh;
          _speedReadings.add(speedKmh);
          _avgSpeedKmh = _speedReadings.reduce((a, b) => a + b) / _speedReadings.length;
        });
      }
      _lastPosition = pos;
    });
  }

  void _stopTracking() {
    _positionSub?.cancel();
    _timer?.cancel();
    setState(() { _tracking = false; _currentSpeedKmh = 0; });
  }

  Future<void> _saveSession() async {
    if (_distanceKm < 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Distance too short to save'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _saving = true);
    final uid = DBHelper.currentUid!;
    final calories = (_distanceKm * 40).roundToDouble(); // ~40 cal/km cycling

    final session = CyclingSession(
      userId: uid,
      distanceKm: double.parse(_distanceKm.toStringAsFixed(2)),
      durationMinutes: (_elapsedSeconds / 60).round(),
      avgSpeedKmh: double.parse(_avgSpeedKmh.toStringAsFixed(1)),
      maxSpeedKmh: double.parse(_maxSpeedKmh.toStringAsFixed(1)),
      calories: calories,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    await DBHelper.insertCyclingSession(session);
    await _loadSessions();

    setState(() {
      _saving = false;
      _distanceKm = 0;
      _elapsedSeconds = 0;
      _avgSpeedKmh = 0;
      _maxSpeedKmh = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Cycling session saved!'),
        ]),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

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
        title: const Text('Cycling Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Weather card
              if (_loadingWeather)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                  child: const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: kGreen, strokeWidth: 2))),
                )
              else if (_weather != null)
                _buildWeatherCard(_weather!),
              const SizedBox(height: 8),

              // Live stats card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _tracking ? [kGreen, kDarkGreen] : [kCardDark, kCardDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _tracking ? kGreen.withOpacity(0.5) : Colors.white12),
                  boxShadow: _tracking ? [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))] : [],
                ),
                child: Column(
                  children: [
                    // Speed
                    Text(
                      _currentSpeedKmh.toStringAsFixed(1),
                      style: TextStyle(
                        color: _tracking ? Colors.white : Colors.white38,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text('km/h', style: TextStyle(color: _tracking ? Colors.white70 : Colors.white24, fontSize: 16)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _liveStat(_formatTime(_elapsedSeconds), 'Time', Icons.timer_rounded),
                        _vDivider(),
                        _liveStat('${_distanceKm.toStringAsFixed(2)}km', 'Distance', Icons.route_rounded),
                        _vDivider(),
                        _liveStat('${_avgSpeedKmh.toStringAsFixed(1)}', 'Avg km/h', Icons.speed_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Max speed badge
              if (_maxSpeedKmh > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 16),
                      const SizedBox(width: 6),
                      Text('Max Speed: ${_maxSpeedKmh.toStringAsFixed(1)} km/h',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Control buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _tracking ? _stopTracking : _startTracking,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _tracking ? [Colors.red.shade400, Colors.red.shade700] : [kGreen, kDarkGreen],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(
                            color: (_tracking ? Colors.red : kGreen).withOpacity(0.4),
                            blurRadius: 12, offset: const Offset(0, 4),
                          )],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_tracking ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Text(_tracking ? 'Stop' : 'Start Ride', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!_tracking && _distanceKm > 0) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _saving ? null : _saveSession,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: _saving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: kGreen, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, color: Colors.white70, size: 24),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),

              // Past sessions
              if (!_loadingSessions) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Past Rides', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${_sessions.length} sessions', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_sessions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: kCardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                    child: const Center(child: Text('No rides yet. Start your first ride!', style: TextStyle(color: Colors.white38))),
                  )
                else
                  ..._sessions.map((s) => _sessionCard(s)),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionCard(CyclingSession s) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kGreen, kDarkGreen]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.directions_bike_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.distanceKm} km', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${s.durationMinutes} min · ${s.avgSpeedKmh} km/h avg · ${s.date}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${s.calories.toInt()} cal', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Max: ${s.maxSpeedKmh} km/h', style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ],
        ),
      );

  Widget _liveStat(String value, String label, IconData icon) => Column(
        children: [
          Icon(icon, color: _tracking ? Colors.white70 : Colors.white24, size: 16),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: _tracking ? Colors.white : Colors.white38, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: _tracking ? Colors.white60 : Colors.white24, fontSize: 10)),
        ],
      );

  Widget _vDivider() => Container(width: 1, height: 40, color: Colors.white24);

  Widget _buildWeatherCard(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>? ?? {};
    final temp     = (current['temperature_2m'] ?? 0).toDouble();
    final humidity = (current['relative_humidity_2m'] ?? 0).toInt();
    final wind     = (current['wind_speed_10m'] ?? 0).toDouble();
    final windDir  = (current['wind_direction_10m'] ?? 0).toInt();
    final precip   = (current['precipitation'] ?? 0).toDouble();
    final code     = (current['weather_code'] ?? 0).toInt();

    final emoji    = _weatherEmoji(code);
    final condition = _weatherCondition(code);
    final suggestion = _cyclingSuggestion(temp, wind, precip);
    final suggColor  = suggestion['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(condition, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Cycling conditions', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _loadWeather,
                child: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _weatherStat('${temp.round()}°C', 'Temp', Icons.thermostat_rounded, Colors.orange),
              _weatherStat('$wind km/h', 'Wind', Icons.air_rounded, Colors.lightBlue),
              _weatherStat('$humidity%', 'Humidity', Icons.water_drop_rounded, Colors.blue),
              _weatherStat('${precip}mm', 'Rain', Icons.umbrella_rounded, Colors.indigo),
            ],
          ),
          const SizedBox(height: 14),

          // Cycling suggestion
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: suggColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: suggColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(suggestion['icon'] as IconData, color: suggColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion['text'] as String,
                    style: TextStyle(color: suggColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherStat(String value, String label, IconData icon, Color color) => Column(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ],
  );

  Map<String, dynamic> _cyclingSuggestion(double temp, double wind, double precip) {
    if (precip > 1.0) return {'text': 'Rain detected — slippery roads, ride carefully or stay indoors.', 'icon': Icons.warning_rounded, 'color': Colors.red};
    if (wind > 30)    return {'text': 'Strong winds (${ wind.round()} km/h) — expect resistance, plan your route.', 'icon': Icons.air_rounded, 'color': Colors.orange};
    if (temp > 35)    return {'text': 'Very hot! Stay hydrated and avoid peak hours.', 'icon': Icons.local_fire_department_rounded, 'color': Colors.deepOrange};
    if (temp < 15)    return {'text': 'Cool weather — great for cycling! Wear layers.', 'icon': Icons.check_circle_rounded, 'color': Colors.lightBlue};
    return {'text': 'Great cycling conditions! Enjoy your ride.', 'icon': Icons.check_circle_rounded, 'color': kGreen};
  }

  String _weatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 49) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌦️';
    return '⛈️';
  }

  String _weatherCondition(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 67) return 'Rainy';
    if (code <= 77) return 'Snowy';
    if (code <= 82) return 'Rain Showers';
    return 'Thunderstorm';
  }
}
