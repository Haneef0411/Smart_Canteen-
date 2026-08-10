import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.greenSoft,
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.restaurant_menu_rounded,
      color: AppColors.green,
      size: size * .52,
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.greenSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 42, color: AppColors.green),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final danger = lower == 'sold out' || lower == 'cancelled';
    final warning =
        lower == 'limited' || lower == 'pending' || lower == 'preparing';
    final color = danger
        ? AppColors.danger
        : warning
        ? AppColors.warning
        : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.green,
    ),
  );
}
