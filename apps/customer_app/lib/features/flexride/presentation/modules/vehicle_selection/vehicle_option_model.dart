import 'package:flutter/material.dart';

class VehicleOption {
  final String name;
  final String desc;
  final int price;
  final String priceFormatted;
  final IconData icon;

  const VehicleOption({
    required this.name,
    required this.desc,
    required this.price,
    required this.priceFormatted,
    required this.icon,
  });
}
