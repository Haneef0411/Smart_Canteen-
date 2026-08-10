import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'cart_checkout.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Orders',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestoreService.orders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Orders unavailable',
            message: 'Check your connection and try again.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final docs = snapshot.data!.docs
            .where((d) => d.data()['userId'] == uid)
            .toList();
        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            message: 'Your active and previous orders will appear here.',
          );
        }
        final active = docs
            .where(
              (d) => !['Collected', 'Cancelled'].contains(d.data()['status']),
            )
            .toList();
        final previous = docs
            .where(
              (d) => ['Collected', 'Cancelled'].contains(d.data()['status']),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (active.isNotEmpty) ...[
              const OrderHeading('Active orders'),
              ...active.map((d) => OrderCard(data: d.data())),
            ],
            if (previous.isNotEmpty) ...[
              const SizedBox(height: 20),
              const OrderHeading('Previous orders'),
              ...previous.map((d) => OrderCard(data: d.data())),
            ],
          ],
        );
      },
    ),
  );
}

class OrderHeading extends StatelessWidget {
  const OrderHeading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    ),
  );
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final ts = data['createdAt'] as Timestamp?;
    final date = ts?.toDate();
    final status = data['status'] as String? ?? 'Pending';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(data: data)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${data['orderNumber'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    StatusBadge(status),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 17,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date == null ? 'Just now' : _date(date),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const Spacer(),
                    Text(
                      '${data['itemCount'] ?? 0} items',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                const Divider(height: 26),
                Row(
                  children: [
                    Text(
                      money((data['total'] as num?)?.toDouble() ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Pickup ${data['pickupTime'] ?? '—'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.data});
  final Map<String, dynamic> data;
  static const steps = [
    'Pending',
    'Confirmed',
    'Preparing',
    'Ready',
    'Collected',
  ];
  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'Pending';
    final current = steps.indexOf(status);
    final items = (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(title: Text('Order #${data['orderNumber'] ?? ''}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Text(
                'Order status',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              StatusBadge(status),
            ],
          ),
          const SizedBox(height: 20),
          if (status == 'Cancelled')
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'This order was cancelled.',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(
                    steps.length,
                    (i) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Icon(
                              i <= current
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: i <= current
                                  ? AppColors.green
                                  : AppColors.border,
                            ),
                            if (i < steps.length - 1)
                              Container(
                                width: 2,
                                height: 28,
                                color: i < current
                                    ? AppColors.green
                                    : AppColors.border,
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            steps[i],
                            style: TextStyle(
                              fontWeight: i == current
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          const OrderHeading('Order details'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item['quantity']} × ${item['name']}',
                            ),
                          ),
                          Text(
                            money(
                              ((item['price'] as num?)?.toDouble() ?? 0) *
                                  ((item['quantity'] as num?)?.toInt() ?? 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  SummaryRow(
                    label: 'Total',
                    value: money((data['total'] as num?)?.toDouble() ?? 0),
                    bold: true,
                  ),
                  const SizedBox(height: 12),
                  SummaryRow(
                    label: 'Pickup time',
                    value: data['pickupTime'] as String? ?? '—',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestoreService.profile(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          final name = data['name'] as String? ?? user.displayName ?? 'Student';
          final email = data['email'] as String? ?? user.email ?? '';
          final phone = data['phone'] as String? ?? '';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.greenSoft,
                        child: Text(
                          name.isEmpty ? 'S' : name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            if (phone.isNotEmpty)
                              Text(
                                phone,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit profile',
                        onPressed: () => _edit(context, name, phone),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const OrderHeading('Account'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Edit profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _edit(context, name, phone),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Reset password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        try {
                          await authService.resetPassword(email);
                          if (context.mounted) {
                            showMessage(context, 'Password reset email sent.');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showMessage(
                              context,
                              authService.message(e),
                              error: true,
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const OrderHeading('Support'),
              const Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.help_outline),
                      title: Text('Help & support'),
                      subtitle: Text('Contact your canteen administration'),
                    ),
                    Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('About Smart Canteen'),
                      subtitle: Text('Version 1.0.0'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: AppColors.danger),
                label: const Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, String name, String phone) async {
    final n = TextEditingController(text: name),
        p = TextEditingController(text: phone);
    final save = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: n,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: p,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save == true && n.text.trim().isNotEmpty) {
      try {
        await firestoreService.updateProfile({
          'name': n.text.trim(),
          'phone': p.text.trim(),
        });
        if (context.mounted) showMessage(context, 'Profile updated.');
      } catch (_) {
        if (context.mounted) {
          showMessage(
            context,
            'Profile could not be updated. Try again.',
            error: true,
          );
        }
      }
    }
    n.dispose();
    p.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to place an order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (yes == true) {
      cart.clear();
      await authService.logout();
    }
  }
}

String _date(DateTime d) {
  final now = DateTime.now();
  final day = now.year == d.year && now.month == d.month && now.day == d.day
      ? 'Today'
      : '${d.day}/${d.month}/${d.year}';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$day, $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}
