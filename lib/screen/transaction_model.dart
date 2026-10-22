import 'package:flutter/material.dart';

class TransactionModel {
  final String title; // ชื่อหมวดหมู่ เช่น อาหารหลัก
  final double amount;
  final DateTime dateTime;
  final IconData icon;
  final Color iconBgColor;
  final bool isIncome;

  /// รายละเอียดเพิ่มเติม (ไม่บังคับ) เช่น "ข้าวเหนียวหมูปิ้ง"
  final String note;

  const TransactionModel({
    required this.title,
    required this.amount,
    required this.dateTime,
    required this.icon,
    required this.iconBgColor,
    required this.isIncome,
    this.note = '',
  });
}