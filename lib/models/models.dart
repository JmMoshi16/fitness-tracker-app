import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  String username;
  String email;

  UserModel({required this.uid, required this.username, required this.email});

  Map<String, dynamic> toMap() => {'username': username, 'email': email};

  factory UserModel.fromDoc(DocumentSnapshot doc) => UserModel(
        uid: doc.id,
        username: doc['username'],
        email: doc['email'],
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

  Workout({
    this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.durationMinutes,
    required this.notes,
    required this.date,
    this.photoPath,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'type': type,
        'durationMinutes': durationMinutes,
        'notes': notes,
        'date': date,
        'photoPath': photoPath ?? '',
      };

  factory Workout.fromDoc(DocumentSnapshot doc) => Workout(
        id: doc.id,
        userId: doc['userId'],
        title: doc['title'],
        type: doc['type'],
        durationMinutes: doc['durationMinutes'],
        notes: doc['notes'],
        date: doc['date'],
        photoPath: doc.data().toString().contains('photoPath') ? doc['photoPath'] : '',
      );
}
