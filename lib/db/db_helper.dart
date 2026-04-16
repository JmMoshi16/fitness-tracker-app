import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class DBHelper {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // --- Auth ---
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
    final uid = currentUid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromDoc(doc) : null;
  }

  static Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  // --- Workout CRUD ---
  static Future<void> insertWorkout(Workout w) async {
    await _db.collection('workouts').add(w.toMap());
  }

  static Future<List<Workout>> getWorkouts(String userId) async {
    final snap = await _db
        .collection('workouts')
        .where('userId', isEqualTo: userId)
        .get();
    final list = snap.docs.map((d) => Workout.fromDoc(d)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<void> updateWorkout(Workout w) async {
    await _db.collection('workouts').doc(w.id).update(w.toMap());
  }

  static Future<void> deleteWorkout(String id) async {
    await _db.collection('workouts').doc(id).delete();
  }
}
