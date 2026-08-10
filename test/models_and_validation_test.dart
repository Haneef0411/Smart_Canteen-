import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen_app/models/models.dart';
import 'package:smart_canteen_app/utils/validators.dart';

void main() {
  group('authentication validation', () {
    test('login requires a valid email and password', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('student@example.com'), isNull);
      expect(Validators.requiredPassword(''), isNotNull);
      expect(Validators.requiredPassword('secret'), isNull);
    });

    test('registration validates required fields and confirmation', () {
      expect(Validators.name('A'), isNotNull);
      expect(Validators.registrationNumber('  '), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('strongpass'), isNull);
      expect(Validators.confirmation('different', 'strongpass'), isNotNull);
      expect(Validators.confirmation('strongpass', 'strongpass'), isNull);
    });
  });

  group('role parsing', () {
    test('routes known Firestore roles safely', () {
      expect(UserProfile.fromMap({'role': 'student'}).role, UserRole.student);
      expect(UserProfile.fromMap({'role': 'staff'}).role, UserRole.staff);
      expect(UserProfile.fromMap({'role': 'admin'}).role, UserRole.admin);
      expect(
        UserProfile.fromMap({'role': 'unexpected'}).role,
        UserRole.student,
      );
    });

    test('reads new and legacy registration number fields', () {
      expect(
        UserProfile.fromMap({'registrationNumber': 'REG-1'}).registrationNumber,
        'REG-1',
      );
      expect(
        UserProfile.fromMap({'studentId': 'LEGACY-1'}).registrationNumber,
        'LEGACY-1',
      );
    });
  });

  test('order model serializes canonical fields and reads legacy aliases', () {
    final order = OrderData.fromMap('order-1', {
      'status': 'Confirmed',
      'pickupTime': '12:30 PM',
      'total': 850,
      'itemCount': 2,
      'createdAt': DateTime(2026, 8, 10),
      'items': [
        {'name': 'Rice', 'price': 425, 'quantity': 2},
      ],
    });
    expect(order.status, 'Accepted');
    expect(order.total, 850);
    expect(order.pickupTime, '12:30 PM');
    expect(order.toMap()['totalAmount'], 850);
    expect(order.toMap()['orderStatus'], 'Accepted');
  });
}
