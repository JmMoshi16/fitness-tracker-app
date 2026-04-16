import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Uses the free wger REST API for exercise information
  static const _base = 'https://wger.de/api/v2';

  static Future<List<Map<String, dynamic>>> fetchExercises({String? category}) async {
    final uri = Uri.parse('$_base/exercise/?format=json&language=2&limit=10');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data['results']);
    }
    throw Exception('Failed to load exercises');
  }

  static Future<List<Map<String, dynamic>>> fetchExerciseCategories() async {
    final uri = Uri.parse('$_base/exercisecategory/?format=json');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data['results']);
    }
    throw Exception('Failed to load categories');
  }
}
