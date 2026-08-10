import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'cart_checkout.dart';
import 'orders_profile.dart';
import 'staff.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: firestoreService.profile(),
        builder: (context, snapshot) {
          final profile = UserProfile.fromMap(snapshot.data?.data());
          return ListenableBuilder(
            listenable: cart,
            builder: (context, _) {
              final isStaff = profile.isStaff;
              return Scaffold(
                body: IndexedStack(
                  index: _index,
                  children: [
                    MenuScreen(onCart: () => setState(() => _index = 2)),
                    const OrdersScreen(),
                    CartScreen(onBrowse: () => setState(() => _index = 0)),
                    const ProfileScreen(),
                    if (isStaff) const StaffScreen(),
                  ],
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: 'Orders',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: cart.count > 0,
                        label: Text('${cart.count}'),
                        child: const Icon(Icons.shopping_bag_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: cart.count > 0,
                        label: Text('${cart.count}'),
                        child: const Icon(Icons.shopping_bag),
                      ),
                      label: 'Cart',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                    if (isStaff)
                      const NavigationDestination(
                        icon: Icon(Icons.manage_accounts_outlined),
                        selectedIcon: Icon(Icons.manage_accounts),
                        label: 'Manage',
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.onCart});
  final VoidCallback onCart;
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late final AnimationController _entrance;
  String _query = '', _category = 'All';
  static const categories = ['All', ...FoodItem.categories];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _search.dispose();
    _entrance.dispose();
    super.dispose();
  }

  List<FoodItem> filter(List<FoodItem> all) => all.where((f) {
    final q = _query.toLowerCase();
    return (_category == 'All' || f.category == _category) &&
        '${f.name} ${f.description} ${f.category}'.toLowerCase().contains(q);
  }).toList();

  Future<void> _addItem(FoodItem item) async {
    var selected = item;
    if (item.id == 'juice') {
      final selection =
          await showModalBottomSheet<({String variety, int quantity})>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (context) => _JuiceVarietySheet(price: item.price),
          );
      if (selection == null || !mounted) return;
      selected = item.asJuiceVariety(selection.variety);
      cart.add(selected, quantity: selection.quantity);
      showMessage(
        context,
        '${selection.quantity} × ${selected.name} added to cart.',
      );
      setState(() {});
      return;
    }
    final quantity = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _MenuQuantitySheet(item: item),
    );
    if (quantity == null || !mounted) return;
    cart.add(selected, quantity: quantity);
    if (!mounted) return;
    showMessage(context, '$quantity × ${selected.name} added to cart.');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName =
        user?.displayName?.trim().split(' ').firstOrNull ?? 'Student';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.greenDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Canteen',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              'University canteen',
              style: TextStyle(fontSize: 12, color: Color(0xFFFFE2D4)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open cart',
            onPressed: widget.onCart,
            icon: Badge(
              isLabelVisible: cart.count > 0,
              label: Text('${cart.count}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.menu(),
        builder: (context, snapshot) {
          final items = snapshot.hasData
              ? snapshot.data!.docs
                    .map((d) => FoodItem.fromMap(d.id, d.data()))
                    .toList()
              : const <FoodItem>[];
          if (snapshot.hasData) cart.sync(items);
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
          final filtered = filter(items);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _entrance,
                          curve: const Interval(0, .65, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, -.08),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _entrance,
                                  curve: const Interval(
                                    0,
                                    .65,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                              ),
                          child: _MenuHero(firstName: firstName),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _query = v.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search food or drinks',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final c = categories[i];
                            return ChoiceChip(
                              label: Text(c),
                              selected: c == _category,
                              onSelected: (_) => setState(() => _category = c),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _category == 'All' ? 'Today’s menu' : _category,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            '${filtered.length} items',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No meals found',
                    message:
                        'Try another search or choose a different category.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.crossAxisExtent >= 760
                          ? 2
                          : 1;
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 190,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => FoodCard(
                            item: filtered[i],
                            index: i,
                            animation: _entrance,
                            onAdded: () => _addItem(filtered[i]),
                          ),
                          childCount: filtered.length,
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _JuiceVarietySheet extends StatefulWidget {
  const _JuiceVarietySheet({required this.price});
  final double price;

  @override
  State<_JuiceVarietySheet> createState() => _JuiceVarietySheetState();
}

class _JuiceVarietySheetState extends State<_JuiceVarietySheet> {
  String _variety = FoodItem.juiceVarieties.first;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your fresh juice',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick a freshly blended flavour for your order.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          for (final variety in FoodItem.juiceVarieties)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => setState(() => _variety = variety),
                selected: _variety == variety,
                selectedTileColor: AppColors.orangeSoft,
                tileColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: _variety == variety
                        ? AppColors.orange
                        : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_drink_rounded,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  '$variety Juice',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: Icon(
                  _variety == variety
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _variety == variety
                      ? AppColors.orange
                      : AppColors.muted,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quantity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              _QuantityButton(
                icon: Icons.remove,
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _QuantityButton(
                icon: Icons.add,
                onPressed: _quantity < 20
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, (
                variety: _variety,
                quantity: _quantity,
              )),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                'Add $_quantity • LKR ${(widget.price * _quantity).toStringAsFixed(0)}',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MenuQuantitySheet extends StatefulWidget {
  const _MenuQuantitySheet({required this.item});
  final FoodItem item;

  @override
  State<_MenuQuantitySheet> createState() => _MenuQuantitySheetState();
}

class _MenuQuantitySheetState extends State<_MenuQuantitySheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: widget.item.imageAsset == null
                      ? ColoredBox(
                          color: AppColors.greenSoft,
                          child: Icon(
                            widget.item.icon,
                            size: 42,
                            color: AppColors.green,
                          ),
                        )
                      : Image.asset(widget.item.imageAsset!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'LKR ${widget.item.price.toStringAsFixed(0)} each',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Select quantity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              _QuantityButton(
                icon: Icons.remove,
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _QuantityButton(
                icon: Icons.add,
                onPressed: _quantity < 20
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, _quantity),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                'Add $_quantity • LKR ${(widget.item.price * _quantity).toStringAsFixed(0)}',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      IconButton.filledTonal(onPressed: onPressed, icon: Icon(icon));
}

class _MenuHero extends StatelessWidget {
  const _MenuHero({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.greenDark, AppColors.green],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: AppColors.greenDark.withValues(alpha: .22),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HELLO, ${firstName.toUpperCase()}',
                style: const TextStyle(
                  color: Color(0xFFFFE2D4),
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Good food,\nready when you are.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '●  Open today  •  Fast pickup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: .35),
              width: 5,
            ),
          ),
          child: const Icon(
            Icons.lunch_dining_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
      ],
    ),
  );
}

class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.item,
    required this.onAdded,
    required this.index,
    required this.animation,
  });
  final FoodItem item;
  final VoidCallback onAdded;
  final int index;
  final Animation<double> animation;
  @override
  Widget build(BuildContext context) {
    final sold = item.availability == Availability.soldOut;
    final status = switch (item.availability) {
      Availability.available => 'Available',
      Availability.limited => 'Limited',
      Availability.soldOut => 'Sold Out',
    };
    final start = (0.18 + index * .055).clamp(0.0, .72);
    final end = (start + .28).clamp(0.0, 1.0);
    final entrance = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .12),
          end: Offset.zero,
        ).animate(entrance),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 122,
                    height: double.infinity,
                    color: AppColors.greenSoft,
                    child: item.imageAsset == null
                        ? Icon(item.icon, size: 44, color: AppColors.green)
                        : Image.asset(
                            item.imageAsset!,
                            fit: BoxFit.cover,
                            cacheWidth: 240,
                            errorBuilder: (_, _, _) => Icon(
                              item.icon,
                              size: 44,
                              color: AppColors.green,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          StatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'LKR ${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 17,
                              color: AppColors.orange,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 15,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.minutes} min',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: sold ? null : onAdded,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(52, 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(sold ? 'Unavailable' : 'Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
