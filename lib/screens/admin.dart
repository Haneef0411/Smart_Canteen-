import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'cart_checkout.dart' show money;
import 'staff.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: authService.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.people_outline), text: 'Users'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Categories'),
            Tab(icon: Icon(Icons.storefront_outlined), text: 'Operations'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _AdminOverview(),
          _UsersTab(),
          _CategoriesTab(),
          StaffScreen(),
        ],
      ),
    ),
  );
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview();

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: firestoreService.orders(),
    builder: (context, orderSnapshot) =>
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestoreService.users(),
          builder: (context, userSnapshot) =>
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: firestoreService.menu(),
                builder: (context, menuSnapshot) {
                  if (orderSnapshot.hasError ||
                      userSnapshot.hasError ||
                      menuSnapshot.hasError) {
                    return const EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Analytics unavailable',
                      message: 'Check your permissions and network connection.',
                    );
                  }
                  if (!orderSnapshot.hasData ||
                      !userSnapshot.hasData ||
                      !menuSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final orders = orderSnapshot.data!.docs;
                  final now = DateTime.now();
                  final today = orders.where((doc) {
                    final timestamp = doc.data()['createdAt'] as Timestamp?;
                    final date = timestamp?.toDate();
                    return date != null &&
                        date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;
                  }).toList();
                  final revenue = orders
                      .where(
                        (doc) =>
                            (doc.data()['status'] ?? '').toString() !=
                            'Cancelled',
                      )
                      .fold<double>(
                        0,
                        (total, doc) =>
                            total +
                            (((doc.data()['totalAmount'] ?? doc.data()['total'])
                                        as num?)
                                    ?.toDouble() ??
                                0),
                      );
                  final itemCounts = <String, int>{};
                  for (final order in orders) {
                    for (final raw
                        in (order.data()['items'] as List? ?? const [])) {
                      if (raw is! Map) continue;
                      final name = (raw['name'] ?? 'Unknown').toString();
                      itemCounts[name] =
                          (itemCounts[name] ?? 0) +
                          ((raw['quantity'] as num?)?.toInt() ?? 0);
                    }
                  }
                  final popular = itemCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Live overview',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricCard(
                            label: 'Total orders',
                            value: '${orders.length}',
                            icon: Icons.receipt_long_outlined,
                          ),
                          _MetricCard(
                            label: 'Orders today',
                            value: '${today.length}',
                            icon: Icons.today_outlined,
                          ),
                          _MetricCard(
                            label: 'Users',
                            value: '${userSnapshot.data!.docs.length}',
                            icon: Icons.people_outline,
                          ),
                          _MetricCard(
                            label: 'Menu items',
                            value: '${menuSnapshot.data!.docs.length}',
                            icon: Icons.restaurant_menu,
                          ),
                          _MetricCard(
                            label: 'Revenue',
                            value: money(revenue),
                            icon: Icons.payments_outlined,
                          ),
                          _MetricCard(
                            label: 'Most ordered',
                            value: popular.isEmpty
                                ? '—'
                                : '${popular.first.key} (${popular.first.value})',
                            icon: Icons.star_outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Order status breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final status in const [
                        'Pending',
                        'Accepted',
                        'Preparing',
                        'Ready',
                        'Collected',
                        'Cancelled',
                      ])
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: StatusBadge(status),
                          trailing: Text(
                            '${orders.where((doc) => (doc.data()['status'] ?? '') == status).length}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  );
                },
              ),
        ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.orange),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    ),
  );
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: firestoreService.users(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const EmptyState(
          icon: Icons.lock_outline,
          title: 'Users unavailable',
          message: 'Admin permission is required to manage users.',
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.data!.docs.isEmpty) {
        return const EmptyState(
          icon: Icons.people_outline,
          title: 'No users',
          message: 'Registered users will appear here.',
        );
      }
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: snapshot.data!.docs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final doc = snapshot.data!.docs[index];
          final profile = UserProfile.fromMap(doc.data());
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  profile.name.isEmpty ? '?' : profile.name[0].toUpperCase(),
                ),
              ),
              title: Text(
                profile.name.isEmpty ? 'Unnamed user' : profile.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${profile.email}\n${profile.registrationNumber}'),
              isThreeLine: true,
              trailing: DropdownButton<UserRole>(
                value: profile.role,
                onChanged: doc.id == currentUid
                    ? null
                    : (role) async {
                        if (role != null) {
                          await firestoreService.setUserRole(doc.id, role);
                        }
                      },
                items: UserRole.values
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role.name)),
                    )
                    .toList(),
              ),
            ),
          );
        },
      );
    },
  );
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.categories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Categories unavailable',
              message: 'Check your permissions and connection.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Scaffold(
            body: snapshot.data!.docs.isEmpty
                ? const EmptyState(
                    icon: Icons.category_outlined,
                    title: 'No categories',
                    message: 'Create the first menu category.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data();
                      final active = data['isActive'] as bool? ?? true;
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.category_outlined,
                            color: AppColors.orange,
                          ),
                          title: Text(
                            (data['name'] ?? doc.id).toString(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(active ? 'Active' : 'Hidden'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: active,
                                onChanged: (value) => firestoreService
                                    .setCategoryActive(doc.id, value),
                              ),
                              IconButton(
                                tooltip: 'Delete category',
                                onPressed: () =>
                                    firestoreService.deleteCategory(doc.id),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: const Text('Category'),
            ),
          );
        },
      );

  Future<void> _add(BuildContext context) async {
    final controller = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Add category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (save == true && controller.text.trim().isNotEmpty) {
      await firestoreService.addCategory(controller.text);
    }
    controller.dispose();
  }
}
