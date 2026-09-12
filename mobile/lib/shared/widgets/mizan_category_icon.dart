import 'package:flutter/material.dart';

class MizanCategoryIcon extends StatelessWidget {
  final String? iconKey;
  final String? colorHex;
  final double size;

  const MizanCategoryIcon({
    super.key,
    this.iconKey,
    this.colorHex,
    this.size = 40,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF0F4D3A);
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF0F4D3A);
    }
  }

  IconData _mapIcon(String? key) {
    switch (key?.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;
      case 'local_grocery_store':
      case 'groceries':
        return Icons.local_grocery_store_rounded;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'home':
      case 'housing':
        return Icons.home_rounded;
      case 'directions_car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'bolt':
      case 'bills':
      case 'utilities':
        return Icons.bolt_rounded;
      case 'medical_services':
      case 'health':
        return Icons.medical_services_rounded;
      case 'movie':
      case 'entertainment':
        return Icons.movie_rounded;
      case 'trending_up':
      case 'investments':
        return Icons.trending_up_rounded;
      case 'account_balance_wallet':
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(colorHex);
    final iconData = _mapIcon(iconKey);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: size * 0.52,
          color: color,
        ),
      ),
    );
  }
}
