import 'package:flutter/material.dart';

enum Availability { available, limited, soldOut }

Availability availabilityFrom(String? value) => switch (value) {
  'limited' => Availability.limited,
  'soldOut' => Availability.soldOut,
  _ => Availability.available,
};

String availabilityTo(Availability value) => switch (value) {
  Availability.available => 'available',
  Availability.limited => 'limited',
  Availability.soldOut => 'soldOut',
};

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.minutes,
    required this.icon,
    this.availability = Availability.available,
  });
  final String id, name, description, category;
  final double price;
  final int minutes;
  final IconData icon;
  final Availability availability;

  String? get imageAsset =>
      _imageAssets[id] ??
      (id.startsWith('juice-') ? _imageAssets['juice'] : null);

  static const juiceVarieties = [
    'Mango',
    'Orange',
    'Pineapple',
    'Watermelon',
    'Passion Fruit',
  ];

  FoodItem asJuiceVariety(String variety) {
    final slug = variety.toLowerCase().replaceAll(' ', '-');
    return FoodItem(
      id: 'juice-$slug',
      name: '$variety Juice',
      description: 'Freshly blended $variety juice',
      category: category,
      price: price,
      minutes: minutes,
      icon: icon,
      availability: availability,
    );
  }

  factory FoodItem.fromMap(String id, Map<String, dynamic> data) => FoodItem(
    id: id,
    name: data['name'] as String? ?? 'Unknown',
    description: data['description'] as String? ?? '',
    category: data['category'] as String? ?? 'Meals',
    price: ((data['price'] as num?)?.toDouble() ?? 0),
    minutes: (data['minutes'] as num?)?.toInt() ?? 0,
    icon: _icons[data['icon'] as String?] ?? Icons.restaurant_menu,
    availability: availabilityFrom(data['availability'] as String?),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'category': category,
    'price': price,
    'minutes': minutes,
    'icon': iconName(icon),
    'availability': availabilityTo(availability),
  };

  static const _icons = <String, IconData>{
    'rice': Icons.rice_bowl,
    'vegetable': Icons.eco_outlined,
    'kottu': Icons.dinner_dining,
    'burger': Icons.lunch_dining,
    'roll': Icons.bakery_dining,
    'pizza': Icons.local_pizza_outlined,
    'tea': Icons.emoji_food_beverage,
    'drink': Icons.local_drink_outlined,
    'cake': Icons.cake_outlined,
    'fruit': Icons.icecream_outlined,
    'breakfast': Icons.breakfast_dining,
    'noodles': Icons.ramen_dining,
    'takeout': Icons.takeout_dining,
    'egg': Icons.egg_alt_outlined,
    'fastfood': Icons.fastfood,
    'soup': Icons.soup_kitchen,
  };

  static const _imageAssets = <String, String>{
    'chicken-rice': 'assets/images/menu/chicken-fried-rice.webp',
    'veg-rice': 'assets/images/menu/vegetable-rice.webp',
    'kottu': 'assets/images/menu/chicken-kottu.webp',
    'burger': 'assets/images/menu/chicken-burger.webp',
    'roll': 'assets/images/menu/vegetable-roll.webp',
    'pizza': 'assets/images/menu/cheese-pizza.webp',
    'tea': 'assets/images/menu/milk-tea.webp',
    'juice': 'assets/images/menu/fresh-juice.webp',
    'cake': 'assets/images/menu/chocolate-cake.webp',
    'fruit': 'assets/images/menu/fruit-salad.webp',
  };

  static List<IconData> get iconChoices => _icons.values.toList();

  static String iconName(IconData icon) {
    for (final e in _icons.entries) {
      if (e.value == icon) return e.key;
    }
    return 'food';
  }

  static const categories = ['Meals', 'Snacks', 'Drinks', 'Desserts'];

  /// Initial menu used to populate Firestore the first time the app runs.
  static const seed = <FoodItem>[
    FoodItem(
      id: 'chicken-rice',
      name: 'Chicken Fried Rice',
      description: 'Chicken, vegetables and aromatic rice',
      category: 'Meals',
      price: 650,
      minutes: 18,
      icon: Icons.rice_bowl,
    ),
    FoodItem(
      id: 'veg-rice',
      name: 'Vegetable Rice',
      description: 'Seasonal vegetables with steamed rice',
      category: 'Meals',
      price: 450,
      minutes: 15,
      icon: Icons.eco_outlined,
    ),
    FoodItem(
      id: 'kottu',
      name: 'Chicken Kottu',
      description: 'Chopped roti, chicken and fresh vegetables',
      category: 'Meals',
      price: 700,
      minutes: 20,
      icon: Icons.dinner_dining,
      availability: Availability.limited,
    ),
    FoodItem(
      id: 'burger',
      name: 'Chicken Burger',
      description: 'Grilled chicken, lettuce and house sauce',
      category: 'Snacks',
      price: 550,
      minutes: 12,
      icon: Icons.lunch_dining,
    ),
    FoodItem(
      id: 'roll',
      name: 'Vegetable Roll',
      description: 'Crispy pastry with a savoury filling',
      category: 'Snacks',
      price: 160,
      minutes: 5,
      icon: Icons.bakery_dining,
    ),
    FoodItem(
      id: 'pizza',
      name: 'Cheese Pizza',
      description: 'Personal pizza with mozzarella cheese',
      category: 'Snacks',
      price: 750,
      minutes: 20,
      icon: Icons.local_pizza_outlined,
      availability: Availability.soldOut,
    ),
    FoodItem(
      id: 'tea',
      name: 'Milk Tea',
      description: 'Fresh Ceylon tea with milk',
      category: 'Drinks',
      price: 150,
      minutes: 4,
      icon: Icons.emoji_food_beverage,
    ),
    FoodItem(
      id: 'juice',
      name: 'Fresh Juice',
      description: 'Freshly blended seasonal fruit',
      category: 'Drinks',
      price: 280,
      minutes: 6,
      icon: Icons.local_drink_outlined,
    ),
    FoodItem(
      id: 'cake',
      name: 'Chocolate Cake',
      description: 'Moist chocolate cake slice',
      category: 'Desserts',
      price: 320,
      minutes: 3,
      icon: Icons.cake_outlined,
    ),
    FoodItem(
      id: 'fruit',
      name: 'Fruit Salad',
      description: 'A chilled mix of seasonal fruit',
      category: 'Desserts',
      price: 300,
      minutes: 5,
      icon: Icons.icecream_outlined,
    ),
  ];
}

class UserProfile {
  const UserProfile({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.studentId = '',
    this.role = UserRole.student,
  });
  final String name, email, phone, studentId;
  final UserRole role;

  bool get isStaff => role == UserRole.staff;

  factory UserProfile.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const {};
    return UserProfile(
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      role: map['role'] == 'staff' ? UserRole.staff : UserRole.student,
    );
  }
}

enum UserRole { student, staff }

class OrderData {
  const OrderData({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.pickupTime,
    required this.total,
    required this.itemCount,
    required this.items,
  });
  final String id, status, pickupTime;
  final DateTime createdAt;
  final double total;
  final int itemCount;
  final List<Map<String, dynamic>> items;
}
