import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'cart_checkout.dart' show money;
import 'orders_profile.dart' show OrderDetailScreen;

const _steps = ['Pending', 'Accepted', 'Preparing', 'Ready', 'Collected'];

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'Staff dashboard',
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
          tabs: [
            Tab(text: 'Orders'),
            Tab(text: 'Menu'),
          ],
        ),
      ),
      body: const TabBarView(children: [_StaffOrdersTab(), _StaffMenuTab()]),
    ),
  );
}

class _StaffOrdersTab extends StatefulWidget {
  const _StaffOrdersTab();
  @override
  State<_StaffOrdersTab> createState() => _StaffOrdersTabState();
}

class _StaffOrdersTabState extends State<_StaffOrdersTab> {
  String _filter = 'Active';

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          final all = snapshot.data!.docs;
          final docs = all.where((doc) {
            final status = orderStatusDisplay(
              doc.data()['orderStatus'] ?? doc.data()['status'],
            );
            if (_filter == 'All') return true;
            if (_filter == 'Active') {
              return !['Collected', 'Cancelled'].contains(status);
            }
            return status == _filter;
          }).toList();
          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.task_alt,
              title: 'No matching orders',
              message: 'Try another status filter or wait for a new order.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _OrderMetric(label: 'Pending', count: _count(all, 'Pending')),
                  _OrderMetric(
                    label: 'Preparing',
                    count: _count(all, 'Preparing'),
                  ),
                  _OrderMetric(label: 'Ready', count: _count(all, 'Ready')),
                  _OrderMetric(
                    label: 'Completed today',
                    count: _completedToday(all),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: const [
                    'Active',
                    'All',
                    'Pending',
                    'Accepted',
                    'Preparing',
                    'Ready',
                    'Collected',
                    'Cancelled',
                  ].length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final value = const [
                      'Active',
                      'All',
                      'Pending',
                      'Accepted',
                      'Preparing',
                      'Ready',
                      'Collected',
                      'Cancelled',
                    ][index];
                    return ChoiceChip(
                      label: Text(value),
                      selected: _filter == value,
                      onSelected: (_) => setState(() => _filter = value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              for (final doc in docs) _StaffOrderCard(doc: doc),
            ],
          );
        },
      );

  int _count(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String status,
  ) => docs
      .where(
        (doc) =>
            orderStatusDisplay(
              doc.data()['orderStatus'] ?? doc.data()['status'],
            ) ==
            status,
      )
      .length;

  int _completedToday(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    return docs.where((doc) {
      if (orderStatusDisplay(
            doc.data()['orderStatus'] ?? doc.data()['status'],
          ) !=
          'Collected') {
        return false;
      }
      final date =
          (doc.data()['updatedAt'] as Timestamp? ??
                  doc.data()['createdAt'] as Timestamp?)
              ?.toDate();
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }
}

class _OrderMetric extends StatelessWidget {
  const _OrderMetric({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    width: 145,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.greenDark,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _StaffOrderCard extends StatelessWidget {
  const _StaffOrderCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final status = orderStatusDisplay(data['orderStatus'] ?? data['status']);
    final step = _steps.indexOf(status);
    final done = step == _steps.length - 1 || status == 'Cancelled';
    final last = _steps.last;
    final next = step >= 0 && step < _steps.length - 1
        ? _steps[step + 1]
        : null;
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
                  IconButton(
                    tooltip: 'View order details',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(data: data),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new),
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
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
    XFile? selectedImage;
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
                OutlinedButton.icon(
                  onPressed: () async {
                    final image = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 82,
                      maxWidth: 1200,
                    );
                    if (image != null) setState(() => selectedImage = image);
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    selectedImage == null
                        ? 'Choose image (optional)'
                        : 'Image selected',
                  ),
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
                        decoration: const InputDecoration(
                          labelText: 'Price (LKR)',
                        ),
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
    var imageUrl = '';
    if (selectedImage != null) {
      try {
        imageUrl = await firestoreService.uploadMenuImage(
          id,
          await selectedImage!.readAsBytes(),
          contentType: selectedImage!.mimeType ?? 'image/jpeg',
        );
      } catch (_) {
        if (context.mounted) {
          showMessage(
            context,
            'Image upload failed. The item will use its icon fallback.',
            error: true,
          );
        }
      }
    }
    await firestoreService.addMenuItem(
      FoodItem(
        id: id,
        name: name.text.trim(),
        description: desc.text.trim(),
        category: category,
        price: double.tryParse(price.text.trim()) ?? 0,
        minutes: int.tryParse(minutes.text.trim()) ?? 5,
        icon: icon,
        imageUrl: imageUrl,
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MenuItemImage(item: item),
              ),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(switch (item.availability) {
                    Availability.available => 'Available',
                    Availability.limited => 'Limited',
                    Availability.soldOut => 'Sold Out',
                  }),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Manage ${item.name}',
              onSelected: (action) async {
                if (action == 'edit') {
                  await _editItem(context, item);
                } else if (action == 'enabled') {
                  await firestoreService.setMenuItemEnabled(
                    doc.id,
                    !item.isAvailable,
                  );
                } else if (action == 'availability') {
                  final next = switch (item.availability) {
                    Availability.available => Availability.limited,
                    Availability.limited => Availability.soldOut,
                    Availability.soldOut => Availability.available,
                  };
                  await firestoreService.setAvailability(doc.id, next);
                } else if (action == 'delete') {
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
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem(
                  value: 'enabled',
                  child: ListTile(
                    leading: Icon(
                      item.isAvailable
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    title: Text(item.isAvailable ? 'Disable' : 'Enable'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'availability',
                  child: ListTile(
                    leading: Icon(Icons.tune),
                    title: Text('Change availability'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                    title: Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editItem(BuildContext context, FoodItem item) async {
    final name = TextEditingController(text: item.name);
    final description = TextEditingController(text: item.description);
    final price = TextEditingController(text: item.price.toStringAsFixed(0));
    final minutes = TextEditingController(text: '${item.minutes}');
    var category = item.category;
    var availability = item.availability;
    XFile? selectedImage;
    final save = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${item.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price'),
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
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: FoodItem.categories
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => category = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Availability>(
                  initialValue: availability,
                  decoration: const InputDecoration(labelText: 'Availability'),
                  items: Availability.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(availabilityTo(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => availability = value!),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final image = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 82,
                      maxWidth: 1200,
                    );
                    if (image != null) setState(() => selectedImage = image);
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    selectedImage == null
                        ? 'Replace image'
                        : 'New image selected',
                  ),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (save != true || name.text.trim().isEmpty) return;
    var imageUrl = item.imageUrl;
    if (selectedImage != null) {
      try {
        imageUrl = await firestoreService.uploadMenuImage(
          item.id,
          await selectedImage!.readAsBytes(),
          contentType: selectedImage!.mimeType ?? 'image/jpeg',
        );
      } catch (_) {
        if (context.mounted) {
          showMessage(
            context,
            'Image upload failed; the existing image was kept.',
            error: true,
          );
        }
      }
    }
    await firestoreService.updateMenuItem(
      FoodItem(
        id: item.id,
        name: name.text.trim(),
        description: description.text.trim(),
        category: category,
        price: double.tryParse(price.text.trim()) ?? item.price,
        minutes: int.tryParse(minutes.text.trim()) ?? item.minutes,
        icon: item.icon,
        imageUrl: imageUrl,
        isAvailable: item.isAvailable,
        availability: availability,
      ),
    );
    if (context.mounted) showMessage(context, 'Menu item updated.');
  }
}
