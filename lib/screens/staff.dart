import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'cart_checkout.dart' show money;

const _steps = ['Pending', 'Confirmed', 'Preparing', 'Ready', 'Collected'];

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Manage', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: const TabBar(tabs: [Tab(text: 'Orders'), Tab(text: 'Menu')]),
      ),
      body: const TabBarView(children: [_StaffOrdersTab(), _StaffMenuTab()]),
    ),
  );
}

class _StaffOrdersTab extends StatelessWidget {
  const _StaffOrdersTab();
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
      final docs = snapshot.data!.docs
          .where((d) => !['Collected', 'Cancelled'].contains(d.data()['status']))
          .toList();
      if (docs.isEmpty) {
        return const EmptyState(
          icon: Icons.task_alt,
          title: 'No active orders',
          message: 'Incoming orders will appear here as they are placed.',
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final doc in docs) _StaffOrderCard(doc: doc),
        ],
      );
    },
  );
}

class _StaffOrderCard extends StatelessWidget {
  const _StaffOrderCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final status = data['status'] as String? ?? 'Pending';
    final step = _steps.indexOf(status);
    final done = step == _steps.length - 1 || status == 'Cancelled';
    final last = _steps.last;
    final next = step >= 0 && step < _steps.length - 1 ? _steps[step + 1] : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 6),
              Text(
                '${data['userName'] ?? 'Customer'} · ${data['itemCount'] ?? 0} items · ${data['pickupTime'] ?? '—'}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                (data['items'] as List? ?? [])
                    .cast<Map<String, dynamic>>()
                    .map((i) => '${i['quantity']}×${i['name']}')
                    .join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      money((data['total'] as num?)?.toDouble() ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      ),
                    ),
                  ),
                  if (!done && next != null && next != last)
                    OutlinedButton(
                      onPressed: () =>
                          firestoreService.setOrderStatus(doc.id, next),
                      child: Text('Mark $next'),
                    ),
                  if (!done && next == last)
                    FilledButton(
                      onPressed: () =>
                          firestoreService.setOrderStatus(doc.id, last),
                      child: const Text('Mark Collected'),
                    ),
                  if (!done)
                    IconButton(
                      tooltip: 'Cancel order',
                      onPressed: () =>
                          firestoreService.setOrderStatus(doc.id, 'Cancelled'),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: AppColors.danger,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffMenuTab extends StatelessWidget {
  const _StaffMenuTab();
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: firestoreService.menu(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Menu unavailable',
          message: 'Check your connection and try again.',
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final docs = snapshot.data!.docs;
      return Column(
        children: [
          Expanded(
            child: docs.isEmpty
                ? const EmptyState(
                    icon: Icons.restaurant_menu,
                    title: 'Menu is empty',
                    message: 'Add your first item to get started.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      return _StaffMenuItemCard(doc: doc);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _addItem(context),
                icon: const Icon(Icons.add),
                label: const Text('Add menu item'),
              ),
            ),
          ),
        ],
      );
    },
  );

  Future<void> _addItem(BuildContext context) async {
    final name = TextEditingController(),
        desc = TextEditingController(),
        price = TextEditingController(),
        minutes = TextEditingController();
    String category = FoodItem.categories.first;
    IconData icon = Icons.restaurant_menu;
    final save = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, setState) => AlertDialog(
          title: const Text('Add menu item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price (LKR)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: minutes,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: FoodItem.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Icon',
                    style: Theme.of(dialog).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in FoodItem.iconChoices)
                      ChoiceChip(
                        avatar: Icon(i, size: 18),
                        label: const SizedBox.shrink(),
                        selected: i == icon,
                        onSelected: (_) => setState(() => icon = i),
                      ),
                  ],
                ),
              ],
            ),
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
      ),
    );
    if (save != true || name.text.trim().isEmpty) {
      return;
    }
    final id = 'item-${DateTime.now().millisecondsSinceEpoch}';
    await firestoreService.addMenuItem(
      FoodItem(
        id: id,
        name: name.text.trim(),
        description: desc.text.trim(),
        category: category,
        price: double.tryParse(price.text.trim()) ?? 0,
        minutes: int.tryParse(minutes.text.trim()) ?? 5,
        icon: icon,
      ),
    );
    if (context.mounted) showMessage(context, 'Menu item added.');
  }
}

class _StaffMenuItemCard extends StatelessWidget {
  const _StaffMenuItemCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  @override
  Widget build(BuildContext context) {
    final item = FoodItem.fromMap(doc.id, doc.data());
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: AppColors.green, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${item.category} · ${money(item.price)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(
                    switch (item.availability) {
                      Availability.available => 'Available',
                      Availability.limited => 'Limited',
                      Availability.soldOut => 'Sold Out',
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cycle availability',
              onPressed: () {
                final next = switch (item.availability) {
                  Availability.available => Availability.limited,
                  Availability.limited => Availability.soldOut,
                  Availability.soldOut => Availability.available,
                };
                firestoreService.setAvailability(doc.id, next);
              },
              icon: const Icon(Icons.tune),
            ),
            IconButton(
              tooltip: 'Delete ${item.name}',
              onPressed: () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Delete item?'),
                    content: Text('Remove ${item.name} from the menu?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (yes == true) {
                  await firestoreService.deleteMenuItem(doc.id);
                }
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}
