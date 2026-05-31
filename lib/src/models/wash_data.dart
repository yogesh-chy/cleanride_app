import 'package:flutter/material.dart';

class PackageInfo {
  const PackageInfo({
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
  });

  final String name;
  final double price;
  final int duration; // in minutes
  final List<String> features;
}

class WashData {
  static const Map<String, PackageInfo> packagePricing = {
    'basic': PackageInfo(
      name: 'Basic Wash',
      price: 500,
      duration: 20,
      features: ['Exterior Wash', 'Rinse & Dry', 'Tire Cleaning'],
    ),
    'standard': PackageInfo(
      name: 'Standard Wash',
      price: 1000,
      duration: 40,
      features: [
        'Exterior Wash',
        'Interior Vacuum',
        'Dashboard Wipe',
        'Tire Shine',
        'Air Freshener'
      ],
    ),
    'premium': PackageInfo(
      name: 'Premium Detail',
      price: 2000,
      duration: 75,
      features: [
        'Full Exterior Polish',
        'Interior Deep Clean',
        'Leather Conditioning',
        'Engine Bay Clean',
        'Ceramic Spray',
        'Tire Dressing'
      ],
    ),
  };

  static const Map<String, String> vehicleTypeLabels = {
    'car': 'Car',
    'suv': 'SUV',
    'bike': 'Bike',
  };

  static const Map<String, String> statusLabels = {
    'queued': 'In Queue',
    'in-progress': 'In Progress',
    'washing': 'Washing',
    'drying': 'Drying',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  static const Map<String, Color> statusColors = {
    'queued': Colors.amber,
    'in-progress': Colors.blue,
    'washing': Color(0xFF00B8D4),
    'drying': Colors.purple,
    'completed': Colors.green,
    'cancelled': Colors.red,
  };
}
