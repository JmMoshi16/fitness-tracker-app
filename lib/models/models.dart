import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  String username;
  String email;

  UserModel({required this.uid, required this.username, required this.email});

  Map<String, dynamic> toMap() => {'username': username, 'email': email};

  factory UserModel.fromDoc(DocumentSnapshot doc) => UserModel(
        uid: doc.id,
        username: doc['username'] ?? '',
        email: doc['email'] ?? '',
      );
}

class Workout {
  String? id;
  String userId;
  String title;
  String type;
  int durationMinutes;
  String notes;
  String date;
  String? photoPath;
  double? volume; // total kg lifted
  List<ExerciseLog> exercises;

  Workout({
    this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.durationMinutes,
    required this.notes,
    required this.date,
    this.photoPath,
    this.volume,
    this.exercises = const [],
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'type': type,
        'durationMinutes': durationMinutes,
        'notes': notes,
        'date': date,
        'photoPath': photoPath ?? '',
        'volume': volume ?? 0.0,
      };

  factory Workout.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Workout(
      id: doc.id,
      userId: d['userId'] ?? '',
      title: d['title'] ?? '',
      type: d['type'] ?? '',
      durationMinutes: d['durationMinutes'] ?? 0,
      notes: d['notes'] ?? '',
      date: d['date'] ?? '',
      photoPath: d['photoPath'] ?? '',
      volume: (d['volume'] ?? 0.0).toDouble(),
    );
  }
}

// A single set within an exercise
class ExerciseSet {
  int reps;
  double weight; // kg
  bool completed;

  ExerciseSet({required this.reps, required this.weight, this.completed = false});

  Map<String, dynamic> toMap() => {'reps': reps, 'weight': weight, 'completed': completed};

  factory ExerciseSet.fromMap(Map<String, dynamic> m) => ExerciseSet(
        reps: m['reps'] ?? 0,
        weight: (m['weight'] ?? 0.0).toDouble(),
        completed: m['completed'] ?? false,
      );
}

// An exercise within a workout (e.g. Bench Press: 3 sets)
class ExerciseLog {
  String? id;
  String userId;
  String workoutId;
  String exerciseName;
  String muscleGroup;
  List<ExerciseSet> sets;
  String notes;
  String date;

  ExerciseLog({
    this.id,
    required this.userId,
    required this.workoutId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
    this.notes = '',
    required this.date,
  });

  double get totalVolume => sets.fold(0.0, (s, e) => s + e.reps * e.weight);
  double get maxWeight => sets.isEmpty ? 0 : sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  int get totalReps => sets.fold(0, (s, e) => s + e.reps);

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'workoutId': workoutId,
        'exerciseName': exerciseName,
        'muscleGroup': muscleGroup,
        'sets': sets.map((s) => s.toMap()).toList(),
        'notes': notes,
        'date': date,
      };

  factory ExerciseLog.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExerciseLog(
      id: doc.id,
      userId: d['userId'] ?? '',
      workoutId: d['workoutId'] ?? '',
      exerciseName: d['exerciseName'] ?? '',
      muscleGroup: d['muscleGroup'] ?? '',
      sets: (d['sets'] as List<dynamic>? ?? []).map((s) => ExerciseSet.fromMap(Map<String, dynamic>.from(s))).toList(),
      notes: d['notes'] ?? '',
      date: d['date'] ?? '',
    );
  }
}

// PR (Personal Record) tracking
class PRRecord {
  String? id;
  String userId;
  String exerciseName;
  double weight;
  int reps;
  String date;

  PRRecord({
    this.id,
    required this.userId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'exerciseName': exerciseName,
        'weight': weight,
        'reps': reps,
        'date': date,
      };

  factory PRRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PRRecord(
      id: doc.id,
      userId: d['userId'] ?? '',
      exerciseName: d['exerciseName'] ?? '',
      weight: (d['weight'] ?? 0.0).toDouble(),
      reps: d['reps'] ?? 0,
      date: d['date'] ?? '',
    );
  }
}

// Workout Template (Push/Pull/Legs etc.)
class WorkoutTemplate {
  String? id;
  String userId;
  String name;
  String category; // Push, Pull, Legs, Full Body, Custom
  List<String> exercises; // exercise names
  String notes;

  WorkoutTemplate({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.exercises,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'category': category,
        'exercises': exercises,
        'notes': notes,
      };

  factory WorkoutTemplate.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WorkoutTemplate(
      id: doc.id,
      userId: d['userId'] ?? '',
      name: d['name'] ?? '',
      category: d['category'] ?? '',
      exercises: List<String>.from(d['exercises'] ?? []),
      notes: d['notes'] ?? '',
    );
  }
}

// GPS Cycling Session
class CyclingSession {
  String? id;
  String userId;
  double distanceKm;
  int durationMinutes;
  double avgSpeedKmh;
  double maxSpeedKmh;
  double calories;
  String date;
  String notes;

  CyclingSession({
    this.id,
    required this.userId,
    required this.distanceKm,
    required this.durationMinutes,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.calories,
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'avgSpeedKmh': avgSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
        'calories': calories,
        'date': date,
        'notes': notes,
      };

  factory CyclingSession.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CyclingSession(
      id: doc.id,
      userId: d['userId'] ?? '',
      distanceKm: (d['distanceKm'] ?? 0.0).toDouble(),
      durationMinutes: d['durationMinutes'] ?? 0,
      avgSpeedKmh: (d['avgSpeedKmh'] ?? 0.0).toDouble(),
      maxSpeedKmh: (d['maxSpeedKmh'] ?? 0.0).toDouble(),
      calories: (d['calories'] ?? 0.0).toDouble(),
      date: d['date'] ?? '',
      notes: d['notes'] ?? '',
    );
  }
}
