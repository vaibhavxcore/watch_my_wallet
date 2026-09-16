import 'package:flutter/material.dart';

class CategoryIconsData {
  IconData getCategoryIcon(String label) {
    switch (label) {
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Grocery':
        return Icons.shopping_cart_rounded;
      case 'Transport':
        return Icons.directions_bus_rounded;
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
      case 'Medical':
        return Icons.medical_services_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Salary':
        return Icons.payments_rounded;
      case 'Business':
        return Icons.business_center_rounded;
      case 'Freelance':
        return Icons.laptop_mac_rounded;
      case 'Investments':
        return Icons.trending_up_rounded;
      case 'Gift':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color getCategoryColor(String label) {
    switch (label) {
      case 'Salary':
      case 'Business':
      case 'Freelance':
      case 'Investments':
      case 'Gift':
        return Colors.green.shade700;
      case 'Food':
        return Colors.orange.shade700;
      case 'Shopping':
        return Colors.purple.shade700;
      case 'Rent':
      case 'Bills':
        return Colors.red.shade700;
      case 'Transport':
      case 'Fuel':
        return Colors.blue.shade700;
      default:
        return Colors.blueGrey.shade800;
    }
  }

  final List<Map<String, dynamic>> expenseLabels = [
    {'label': 'Food', 'icon': Icons.fastfood_rounded},
    {'label': 'Grocery', 'icon': Icons.shopping_cart_rounded},
    {'label': 'Transport', 'icon': Icons.directions_bus_rounded},
    {'label': 'Fuel', 'icon': Icons.local_gas_station_rounded},
    {'label': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'label': 'Rent', 'icon': Icons.home_rounded},
    {'label': 'Bills', 'icon': Icons.receipt_long_rounded},
    {'label': 'Entertainment', 'icon': Icons.movie_rounded},
    {'label': 'Medical', 'icon': Icons.medical_services_rounded},
    {'label': 'Education', 'icon': Icons.school_rounded},
    {'label': 'Others', 'icon': Icons.more_horiz_rounded},
  ];

  final List<Map<String, dynamic>> incomeLabels = [
    {'label': 'Salary', 'icon': Icons.payments_rounded},
    {'label': 'Business', 'icon': Icons.business_center_rounded},
    {'label': 'Freelance', 'icon': Icons.laptop_mac_rounded},
    {'label': 'Investments', 'icon': Icons.trending_up_rounded},
    {'label': 'Gift', 'icon': Icons.card_giftcard_rounded},
    {'label': 'Others', 'icon': Icons.more_horiz_rounded},
  ];
}
