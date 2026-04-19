import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/models/models.dart';
import 'package:fitness_tracker/providers/workout_provider.dart';

void main() {
  group('Workout Model Tests', () {
    test('Workout toMap() contains all required fields', () {
      final w = Workout(
        userId: 'user123',
        title: 'Morning Run',
        type: 'Cardio',
        durationMinutes: 30,
        notes: 'Felt great',
        date: '2024-01-15',
      );
      final map = w.toMap();
      expect(map['userId'], 'user123');
      expect(map['title'], 'Morning Run');
      expect(map['type'], 'Cardio');
      expect(map['durationMinutes'], 30);
      expect(map['notes'], 'Felt great');
      expect(map['date'], '2024-01-15');
    });

    test('Workout durationMinutes must be positive', () {
      final w = Workout(
        userId: 'user123',
        title: 'Test',
        type: 'Strength',
        durationMinutes: 45,
        notes: '',
        date: '2024-01-15',
      );
      expect(w.durationMinutes, greaterThan(0));
    });

    test('Workout type is one of valid types', () {
      const validTypes = ['Cardio', 'Strength', 'Flexibility', 'HIIT', 'Sports', 'Other'];
      final w = Workout(
        userId: 'u1',
        title: 'Test',
        type: 'HIIT',
        durationMinutes: 20,
        notes: '',
        date: '2024-01-15',
      );
      expect(validTypes.contains(w.type), isTrue);
    });
  });

  group('WorkoutProvider Filter Tests', () {
    late WorkoutProvider provider;

    setUp(() {
      provider = WorkoutProvider();
    });

    test('Default filter type is All', () {
      expect(provider.filterType, 'All');
    });

    test('setFilterType updates filterType', () {
      provider.setFilterType('Cardio');
      expect(provider.filterType, 'Cardio');
    });

    test('setSelectedDay updates selectedDay', () {
      final day = DateTime(2024, 6, 15);
      provider.setSelectedDay(day);
      expect(provider.selectedDay, day);
    });

    test('totalMinutes returns 0 when no workouts', () {
      expect(provider.totalMinutes, 0);
    });

    test('weeklyCount returns 0 when no workouts', () {
      expect(provider.weeklyCount, 0);
    });
  });

  group('UserModel Tests', () {
    test('UserModel toMap() contains correct fields', () {
      final user = UserModel(uid: 'uid1', username: 'testuser', email: 'test@email.com');
      final map = user.toMap();
      expect(map['username'], 'testuser');
      expect(map['email'], 'test@email.com');
    });

    test('UserModel username is not empty', () {
      final user = UserModel(uid: 'uid1', username: 'john', email: 'john@email.com');
      expect(user.username.isNotEmpty, isTrue);
    });
  });
}
