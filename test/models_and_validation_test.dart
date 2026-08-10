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
      expect(Validators.registrationNumber(''), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('strongpass'), isNull);
      expect(
        Validators.confirmation('different', 'strongpass'),
        isNotNull,
      );
      expect(
        Validators.confirmation('strongpass', 'strongpass'),
        isNull,
      );
    });
  });

  group('staff order management', () {
    test('order status values are displayed correctly', () {
      expect(orderStatusDisplay('confirmed'), 'Accepted');
      expect(orderStatusDisplay('accepted'), 'Accepted');
      expect(orderStatusDisplay('preparing'), 'Preparing');
      expect(orderStatusDisplay('ready'), 'Ready');
      expect(orderStatusDisplay('collected'), 'Collected');
      expect(orderStatusDisplay('cancelled'), 'Cancelled');
      expect(orderStatusDisplay('canceled'), 'Cancelled');
      expect(orderStatusDisplay('unknown'), 'Pending');
      expect(orderStatusDisplay(null), 'Pending');
    });

    test('order data maps Firestore values correctly', () {
      final order = OrderData.fromMap(
        'SC0001',
        {
          'orderStatus': 'ready',
          'createdAt': '2026-08-10T10:30:00.000',
          'collectionTime': '12:30 PM',
          'totalAmount': 850,
          'itemCount': 2,
          'items': [
            {
              'name': 'Chicken Fried Rice',
              'quantity': 1,
            },
            {
              'name': 'Milk Tea',
              'quantity': 1,
            },
          ],
        },
      );

      expect(order.id, 'SC0001');
      expect(order.status, 'Ready');
      expect(order.pickupTime, '12:30 PM');
      expect(order.total, 850);
      expect(order.itemCount, 2);
      expect(order.items.length, 2);
    });

    test('cancelled order status is normalised correctly', () {
      final order = OrderData.fromMap(
        'SC0002',
        {
          'orderStatus': 'cancelled',
          'createdAt': '2026-08-10T11:00:00.000',
          'collectionTime': '1:00 PM',
          'totalAmount': 450,
          'itemCount': 1,
          'items': [
            {
              'name': 'Vegetable Rice',
              'quantity': 1,
            },
          ],
        },
      );

      expect(order.id, 'SC0002');
      expect(order.status, 'Cancelled');
      expect(order.pickupTime, '1:00 PM');
      expect(order.total, 450);
      expect(order.itemCount, 1);
      expect(order.items.length, 1);
    });
  });
}