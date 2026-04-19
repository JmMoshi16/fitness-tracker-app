import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/models.dart';

class WorkoutProvider extends ChangeNotifier {
  List<Workout> _workouts = [];
  bool _loading = false;
  String _filterType = 'All';
  DateTime _selectedDay = DateTime.now();

  List<Workout> get workouts => _workouts;
  bool get loading => _loading;
  String get filterType => _filterType;
  DateTime get selectedDay => _selectedDay;

  List<Workout> get filtered {
    final dateStr = _fmt(_selectedDay);
    return _workouts.where((w) {
      final typeMatch = _filterType == 'All' || w.type == _filterType;
      return typeMatch && w.date == dateStr;
    }).toList();
  }

  int get weeklyCount {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    return _workouts.where((w) {
      final d = DateTime.tryParse(w.date);
      return d != null && !d.isBefore(startOfWeek) && !d.isAfter(now);
    }).length;
  }

  int get totalMinutes => _workouts.fold(0, (s, w) => s + w.durationMinutes);

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadWorkouts(String uid) async {
    _loading = true;
    notifyListeners();
    _workouts = await DBHelper.getWorkouts(uid);
    _loading = false;
    notifyListeners();
  }

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  Future<void> addWorkout(Workout w) async {
    await DBHelper.insertWorkout(w);
    await loadWorkouts(w.userId);
  }

  Future<void> updateWorkout(Workout w) async {
    await DBHelper.updateWorkout(w);
    await loadWorkouts(w.userId);
  }

  Future<void> deleteWorkout(String id, String uid) async {
    await DBHelper.deleteWorkout(id);
    await loadWorkouts(uid);
  }
}
