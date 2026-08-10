import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'orders_profile.dart' show OrdersScreen;

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.onBrowse});
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: cart,
    builder: (context, _) {
      final entries = cart.items.entries.toList();
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Your cart',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            if (entries.isNotEmpty)
              TextButton(onPressed: cart.clear, child: const Text('Clear')),
          ],
        ),
        body: entries.isEmpty
            ? EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Your cart is empty',
                message: 'Add something delicious from today’s menu.',
                actionLabel: 'Browse menu',
                onAction: onBrowse,
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => CartRow(
                        item: entries[i].key,
                        quantity: entries[i].value,
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          SummaryRow(
                            label: 'Subtotal',
                            value: money(cart.total),
                          ),
                          const SizedBox(height: 8),
                          const SummaryRow(
                            label: 'Service fee',
                            value: 'LKR 0',
                          ),
                          const Divider(height: 28),
                          SummaryRow(
                            label: 'Total',
                            value: money(cart.total),
                            bold: true,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutScreen(),
                                ),
                              ),
                              child: const Text('Continue to checkout'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class CartRow extends StatelessWidget {
  const CartRow({super.key, required this.item, required this.quantity});
  final FoodItem item;
  final int quantity;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 64,
              height: 64,
              color: AppColors.greenSoft,
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
                const SizedBox(height: 4),
                Text(
                  '${money(item.price)} each',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  money(item.price * quantity),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Remove ${item.name}',
                onPressed: () => cart.remove(item),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.danger,
                ),
              ),
              const Text(
                'Quantity',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Decrease quantity',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => cart.decrease(item),
                      color: AppColors.orange,
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      tooltip: 'Increase quantity',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => cart.add(item),
                      color: AppColors.green,
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notes = TextEditingController();
  String? _pickup;
  String _payment = 'Cash on collection';
  bool _loading = false;
  List<String> get times {
    final now = DateTime.now().add(const Duration(minutes: 20));
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute < 30 ? 30 : 60,
    );
    return List.generate(6, (i) {
      final d = start.add(Duration(minutes: 30 * i));
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    if (_pickup == null) {
      showMessage(context, 'Select a pickup time.', error: true);
      return;
    }
    if (_loading || cart.items.isEmpty) return;
    if (_payment == 'Card Payment (Demo)') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Demo card payment'),
          content: const Text(
            'This is a simulation for assessment purposes. No card details or real payment will be requested.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Confirm demo payment'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _loading = true);
    try {
      final snapshot = cart.items;
      final number = await firestoreService.placeOrder(
        items: snapshot.entries
            .map(
              (e) => {
                'id': e.key.id,
                'name': e.key.name,
                'price': e.key.price,
                'quantity': e.value,
              },
            )
            .toList(),
        itemCount: cart.count,
        total: cart.total,
        pickupTime: _pickup!,
        payment: _payment,
        notes: _notes.text.trim(),
      );
      cart.clear();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OrderSuccessScreen(number: number, pickup: _pickup!),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'We could not place your order. Check your connection and try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Checkout',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        SectionTitle(number: '1', title: 'Order summary'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SummaryRow(
                  label: '${cart.count} item${cart.count == 1 ? '' : 's'}',
                  value: money(cart.total),
                ),
                const Divider(height: 24),
                SummaryRow(
                  label: 'Total',
                  value: money(cart.total),
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(number: '2', title: 'Pickup time'),
        const Text(
          'Orders need approximately 15–20 minutes to prepare.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _pickup,
          hint: const Text('Select collection time'),
          items: times
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: _loading ? null : (v) => setState(() => _pickup = v),
        ),
        const SizedBox(height: 24),
        const SectionTitle(number: '3', title: 'Payment method'),
        RadioGroup<String>(
          groupValue: _payment,
          onChanged: (v) => setState(() => _payment = v!),
          child: const Column(
            children: [
              RadioListTile(
                value: 'Cash on collection',
                title: Text('Cash on collection'),
                subtitle: Text('Pay when you collect your order'),
              ),
              RadioListTile(
                value: 'Card Payment (Demo)',
                title: Text('Card Payment (Demo)'),
                subtitle: Text(
                  'Simulated payment — never enter real card details',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _notes,
          maxLines: 3,
          maxLength: 150,
          decoration: const InputDecoration(
            labelText: 'Special instructions (optional)',
            hintText: 'Allergies or preparation notes',
          ),
        ),
        const SizedBox(height: 20),
        SummaryRow(
          label: 'Total payable',
          value: money(cart.total),
          bold: true,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : _place,
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Place order'),
        ),
      ],
    ),
  );
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.number,
    required this.pickup,
  });
  final String number, pickup;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: AppColors.greenSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 52,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Order confirmed',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #$number',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Your order has been sent to the canteen.',
                          textAlign: TextAlign.center,
                        ),
                        const Divider(height: 32),
                        const Text(
                          'Estimated pickup',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          pickup,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text('Back to home'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()),
                    ),
                    child: const Text('View orders'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.number, required this.title});
  final String number, title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.greenSoft,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.green,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });
  final String label, value;
  final bool bold;
  @override
  Widget build(BuildContext context) {
    final s = TextStyle(
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppColors.ink : AppColors.muted,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: s),
        Text(value, style: s),
      ],
    );
  }
}

String money(double amount) => 'LKR ${amount.toStringAsFixed(0)}';
