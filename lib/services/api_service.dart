import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ── wger (exercise tips screen) ───────────────────────────────────────────
  static const _wger = 'https://wger.de/api/v2';

  static Future<List<Map<String, dynamic>>> fetchExercises() async {
    final res = await http.get(Uri.parse('$_wger/exercise/?format=json&language=2&limit=10'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body)['results']);
    }
    throw Exception('Failed to load exercises');
  }

  static Future<List<Map<String, dynamic>>> fetchExerciseCategories() async {
    final res = await http.get(Uri.parse('$_wger/exercisecategory/?format=json'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body)['results']);
    }
    throw Exception('Failed to load categories');
  }

  // ── ExerciseDB via RapidAPI (exercise library screen) ────────────────────
  static const _rapidBase = 'https://exercise-db-fitness-workout-gym.p.rapidapi.com';
  static const _rapidKey  = 'a70a5d06admsh9c3f6ed2a9ed596p17519cjsnca4a24b5d2a6';
  static const _rapidHost = 'exercise-db-fitness-workout-gym.p.rapidapi.com';

  static Map<String, String> get _headers => {
    'x-rapidapi-host': _rapidHost,
    'x-rapidapi-key': _rapidKey,
  };

  /// Fetch all exercises (paginated). [offset] and [limit] control pagination.
  static Future<List<Map<String, dynamic>>> fetchExerciseDB({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_rapidBase/list/exercises?limit=$limit&offset=$offset');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      // API returns either a List or { "exercises": [...] }
      if (data is List) return List<Map<String, dynamic>>.from(data);
      if (data is Map && data['exercises'] != null) {
        return List<Map<String, dynamic>>.from(data['exercises']);
      }
      return [];
    }
    throw Exception('ExerciseDB error ${res.statusCode}');
  }

  /// Filter by muscle group (e.g. "chest", "back", "legs")
  static Future<List<Map<String, dynamic>>> fetchByMuscle(String muscle) async {
    final uri = Uri.parse('$_rapidBase/list/muscles');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Failed to load muscles');
  }

  /// Fetch available body-part / muscle filter options
  static Future<List<String>> fetchBodyParts() async {
    final uri = Uri.parse('$_rapidBase/list/muscles');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data.map((e) => e.toString()).toList();
    }
    throw Exception('Failed to load body parts');
  }

  /// Fetch available equipment options
  static Future<List<String>> fetchEquipment() async {
    final uri = Uri.parse('$_rapidBase/list/equipment');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return data.map((e) => e.toString()).toList();
    }
    throw Exception('Failed to load equipment');
  }

  // ── Edamam Nutrition Analysis via RapidAPI ────────────────────────────────
  static const _edamamBase = 'https://edamam-edamam-nutrition-analysis.p.rapidapi.com';
  static const _edamamHost = 'edamam-edamam-nutrition-analysis.p.rapidapi.com';
  // same RapidAPI key
  static Map<String, String> get _edamamHeaders => {
    'x-rapidapi-host': _edamamHost,
    'x-rapidapi-key': _rapidKey,
  };

  /// Analyse nutrition for a plain-text ingredient string.
  /// [ingr] example: "1 cup rice" or "100g chicken breast"
  static Future<Map<String, dynamic>> analyseNutrition(String ingr) async {
    final uri = Uri.parse(
      '$_edamamBase/api/nutrition-data?nutrition-type=cooking&ingr=${Uri.encodeComponent(ingr)}',
    );
    final res = await http.get(uri, headers: _edamamHeaders);
    if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
    throw Exception('Nutrition API error ${res.statusCode}');
  }

  // ── OpenWeather via RapidAPI ──────────────────────────────────────────────
  static const _weatherBase = 'https://openweather43.p.rapidapi.com';
  static const _weatherHost = 'openweather43.p.rapidapi.com';

  static Map<String, String> get _weatherHeaders => {
    'x-rapidapi-host': _weatherHost,
    'x-rapidapi-key': _rapidKey,
  };

  /// Get current weather by city name.
  static Future<Map<String, dynamic>> fetchWeather(String city) async {
    final uri = Uri.parse(
      '$_weatherBase/weather?q=${Uri.encodeComponent(city)}&units=metric',
    );
    final res = await http.get(uri, headers: _weatherHeaders);
    if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
    throw Exception('Weather API error ${res.statusCode}');
  }

  // ── Exercises by API-Ninjas via RapidAPI ────────────────────────────────
  static const _ninjasBase = 'https://exercises-by-api-ninjas.p.rapidapi.com';
  static const _ninjasHost = 'exercises-by-api-ninjas.p.rapidapi.com';

  static Map<String, String> get _ninjasHeaders => {
    'x-rapidapi-host': _ninjasHost,
    'x-rapidapi-key': _rapidKey,
  };

  /// Fetch exercises filtered by muscle, type, difficulty, or name.
  /// [muscle] e.g. 'biceps', 'chest', 'hamstrings'
  /// [type]   e.g. 'strength', 'cardio', 'stretching'
  /// [difficulty] e.g. 'beginner', 'intermediate', 'expert'
  static Future<List<Map<String, dynamic>>> fetchNinjasExercises({
    String? muscle,
    String? type,
    String? difficulty,
    String? name,
  }) async {
    final params = <String, String>{};
    if (muscle != null && muscle.isNotEmpty)     params['muscle']     = muscle;
    if (type != null && type.isNotEmpty)         params['type']       = type;
    if (difficulty != null && difficulty.isNotEmpty) params['difficulty'] = difficulty;
    if (name != null && name.isNotEmpty)         params['name']       = name;
    final uri = Uri.parse('$_ninjasBase/v1/exercises').replace(queryParameters: params);
    final res = await http.get(uri, headers: _ninjasHeaders);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('API-Ninjas error ${res.statusCode}');
  }

  // ── Open-Meteo Weather (free, no key) ────────────────────────────────
  /// Fetch current weather for cycling. No API key required.
  static Future<Map<String, dynamic>> fetchCyclingWeather(double lat, double lng) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng'
      '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m,weather_code,precipitation'
      '&wind_speed_unit=kmh&timezone=auto',
    );
    final res = await http.get(uri);
    if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
    throw Exception('Open-Meteo error ${res.statusCode}');
  }

  // ── TrueWay Directions via RapidAPI ───────────────────────────────────
  static const _routeBase = 'https://trueway-directions2.p.rapidapi.com';
  static const _routeHost = 'trueway-directions2.p.rapidapi.com';

  static Map<String, String> get _routeHeaders => {
    'x-rapidapi-host': _routeHost,
    'x-rapidapi-key': _rapidKey,
  };

  /// Find a driving/running route between two coordinate pairs.
  /// [stops] format: 'lat1,lng1;lat2,lng2'
  static Future<Map<String, dynamic>> findRoute(String stops) async {
    final uri = Uri.parse('$_routeBase/FindDrivingRoute?stops=${Uri.encodeComponent(stops)}');
    final res = await http.get(uri, headers: _routeHeaders);
    if (res.statusCode == 200) return Map<String, dynamic>.from(jsonDecode(res.body));
    throw Exception('Route API error ${res.statusCode}');
  }
}
