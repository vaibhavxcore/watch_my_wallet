import 'package:flutter/material.dart';

class CategoryIconsData {
  IconData getCategoryIcon(String label) {
    switch (label) {
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Grocery':
        return Icons.shopping_cart_rounded;
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Fuel':
        return Icons.local_gas_station_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Rent':
        return Icons.home_rounded;
      case 'Bills':
        return Icons.receipt_long_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Health':
        return Icons.medical_services_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Subscription':
        return Icons.autorenew_rounded;
      case 'Salary':
        return Icons.payments_rounded;
      case 'Business':
        return Icons.business_center_rounded;
      case 'Freelance':
        return Icons.laptop_mac_rounded;
      case 'Investment':
        return Icons.trending_up_rounded;
      case 'Gift':
        return Icons.card_giftcard_rounded;
      case 'Other':
        return Icons.more_horiz_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color getCategoryColor(String label) {
    switch (label) {
      // Income Colors (gree)
      case 'Salary':
      case 'Business':
      case 'Freelance':
      case 'Investments':
      case 'Gift':
        return const Color(0xFF2E7D32);

      // Expense Colors (specific palette)
      case 'Food':
        return const Color(0xFFEF6C00); // orange
      case 'Grocery':
        return const Color(0xFFFFA000); // amber
      case 'Travel':
        return const Color(0xFF1565C0); // blue
      case 'Fuel':
        return const Color(0xFF0277BD); // light blue
      case 'Shopping':
        return const Color(0xFF7B1FA2); // purple
      case 'Rent':
        return const Color(0xFFC62828); // red
      case 'Bills':
        return const Color(0xFFD84315); // deep Orange
      case 'Entertainment':
        return const Color(0xFF00838F); // teal
      case 'Health':
        return const Color(0xFFAD1457); // pink
      case 'Education':
        return const Color(0xFF283593); // indigo
      case 'Subscription':
        return const Color(0xFF6A1B9A); // deep purple
      case 'Other':
        return const Color(0xFF455A64); // blue Grey
      default:
        return const Color(0xFF455A64); // blue Grey
    }
  }

  final List<Map<String, dynamic>> expenseLabels = [
    {'label': 'Food', 'icon': Icons.fastfood_rounded},
    {'label': 'Grocery', 'icon': Icons.shopping_cart_rounded},
    {'label': 'Travel', 'icon': Icons.flight_takeoff_rounded},
    {'label': 'Fuel', 'icon': Icons.local_gas_station_rounded},
    {'label': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'label': 'Rent', 'icon': Icons.home_rounded},
    {'label': 'Bills', 'icon': Icons.receipt_long_rounded},
    {'label': 'Entertainment', 'icon': Icons.movie_rounded},
    {'label': 'Health', 'icon': Icons.medical_services_rounded},
    {'label': 'Education', 'icon': Icons.school_rounded},
    {'label': 'Subscription', 'icon': Icons.autorenew_rounded},
    {'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  final List<Map<String, dynamic>> incomeLabels = [
    {'label': 'Salary', 'icon': Icons.payments_rounded},
    {'label': 'Business', 'icon': Icons.business_center_rounded},
    {'label': 'Freelance', 'icon': Icons.laptop_mac_rounded},
    {'label': 'Investment', 'icon': Icons.trending_up_rounded},
    {'label': 'Gift', 'icon': Icons.card_giftcard_rounded},
    {'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];
}
