import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class DBHelper {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // ── Auth ────────────────────────────────────────────────────────────────────
  static Future<UserModel> registerUser(String username, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = UserModel(uid: cred.user!.uid, username: username, email: email);
    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  static Future<UserModel> loginUser(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    return UserModel.fromDoc(doc);
  }

  static Future<void> logoutUser() => _auth.signOut();
  static String? get currentUid => _auth.currentUser?.uid;

  static Future<UserModel?> getCurrentUser() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromDoc(doc) : null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUser(UserModel user) async {
    try {
      final docRef = _db.collection('users').doc(user.uid);
      final doc = await docRef.get();
      
      if (doc.exists) {
        await docRef.update(user.toMap());
      } else {
        // Create document if it doesn't exist
        await docRef.set(user.toMap());
      }
    } catch (e) {
      // If update fails, try to create the document
      await _db.collection('users').doc(user.uid).set(user.toMap());
    }
  }

  // ── Workouts ────────────────────────────────────────────────────────────────
  static Future<void> insertWorkout(Workout w) async {
    await _db.collection('workouts').add(w.toMap());
  }

  static Future<List<Workout>> getWorkouts(String userId) async {
    try {
      final snap = await _db.collection('workouts').where('userId', isEqualTo: userId).get();
      final list = snap.docs.map((d) => Workout.fromDoc(d)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      return [];
    }
  }

  static Future<void> updateWorkout(Workout w) async {
    await _db.collection('workouts').doc(w.id).update(w.toMap());
  }

  static Future<void> deleteWorkout(String id) async {
    await _db.collection('workouts').doc(id).delete();
  }

  // ── Exercise Logs ───────────────────────────────────────────────────────────
  static Future<void> insertExerciseLog(ExerciseLog log) async {
    await _db.collection('exercise_logs').add(log.toMap());
    await _checkAndUpdatePR(log.userId, log.exerciseName, log.maxWeight, log.sets.isNotEmpty ? log.sets.first.reps : 0, log.date);
  }

  static Future<List<ExerciseLog>> getExerciseLogs(String userId, {String? exerciseName}) async {
    try {
      Query query = _db.collection('exercise_logs').where('userId', isEqualTo: userId);
      if (exerciseName != null) query = query.where('exerciseName', isEqualTo: exerciseName);
      final snap = await query.get();
      final list = snap.docs.map((d) => ExerciseLog.fromDoc(d)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      return [];
    }
  }

  // Get last log for a specific exercise (for pre-filling)
  static Future<ExerciseLog?> getLastExerciseLog(String userId, String exerciseName) async {
    final snap = await _db
        .collection('exercise_logs')
        .where('userId', isEqualTo: userId)
        .where('exerciseName', isEqualTo: exerciseName)
        .get();
    if (snap.docs.isEmpty) return null;
    final list = snap.docs.map((d) => ExerciseLog.fromDoc(d)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.first;
  }

  // ── PR Records ──────────────────────────────────────────────────────────────
  static Future<void> _checkAndUpdatePR(String userId, String exerciseName, double weight, int reps, String date) async {
    final snap = await _db
        .collection('pr_records')
        .where('userId', isEqualTo: userId)
        .where('exerciseName', isEqualTo: exerciseName)
        .get();

    if (snap.docs.isEmpty) {
      await _db.collection('pr_records').add(PRRecord(
        userId: userId, exerciseName: exerciseName,
        weight: weight, reps: reps, date: date,
      ).toMap());
    } else {
      final existing = PRRecord.fromDoc(snap.docs.first);
      if (weight > existing.weight) {
        await _db.collection('pr_records').doc(snap.docs.first.id).update({
          'weight': weight, 'reps': reps, 'date': date,
        });
      }
    }
  }

  static Future<List<PRRecord>> getPRRecords(String userId) async {
    try {
      final snap = await _db.collection('pr_records').where('userId', isEqualTo: userId).get();
      return snap.docs.map((d) => PRRecord.fromDoc(d)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Workout Templates ───────────────────────────────────────────────────────
  static Future<void> insertTemplate(WorkoutTemplate t) async {
    await _db.collection('workout_templates').add(t.toMap());
  }

  static Future<List<WorkoutTemplate>> getTemplates(String userId) async {
    try {
      final snap = await _db.collection('workout_templates').where('userId', isEqualTo: userId).get();
      return snap.docs.map((d) => WorkoutTemplate.fromDoc(d)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> updateTemplate(WorkoutTemplate t) async {
    await _db.collection('workout_templates').doc(t.id).update(t.toMap());
  }

  static Future<void> deleteTemplate(String id) async {
    await _db.collection('workout_templates').doc(id).delete();
  }

  // ── Cycling Sessions ────────────────────────────────────────────────────────
  static Future<void> insertCyclingSession(CyclingSession s) async {
    await _db.collection('cycling_sessions').add(s.toMap());
  }

  static Future<List<CyclingSession>> getCyclingSessions(String userId) async {
    try {
      final snap = await _db.collection('cycling_sessions').where('userId', isEqualTo: userId).get();
      final list = snap.docs.map((d) => CyclingSession.fromDoc(d)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteCyclingSession(String id) async {
    await _db.collection('cycling_sessions').doc(id).delete();
  }
}
