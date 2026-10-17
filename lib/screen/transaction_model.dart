import 'package:flutter/material.dart';

class TransactionModel {
  final String title;
  final double amount;
  final DateTime dateTime;
  final IconData icon;
  final Color iconBgColor;
  final bool isIncome;

  TransactionModel({
    required this.title,
    required this.amount,
    required this.dateTime,
    required this.icon,
    required this.iconBgColor,
    required this.isIncome,
  });
}