import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firstapp/screen/notification.dart';

/// 📌 รูปโปรไฟล์ที่ใช้ร่วมกันทั้งแอป (หน้าโปรไฟล์ฟังค่านี้เพื่อแสดงรูปล่าสุด)
/// หมายเหตุ: เก็บในหน่วยความจำ ปิดแอปแล้วรูปจะหาย ถ้าต้องการจำข้ามการเปิดแอปต้องเก็บ path ลงเครื่องเพิ่ม
final ValueNotifier<File?> profileImageNotifier = ValueNotifier<File?>(null);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  // รูปที่เลือกไว้ (ยังไม่บันทึกจนกว่าจะกดปุ่ม "บันทึก")
  File? _image = profileImageNotifier.value;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // 📌 โหลดชื่อ/อีเมลของบัญชีที่ login อยู่จาก Firestore
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    _emailController.text = user?.email ?? '';

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        _nameController.text =
            (data?['name'] as String?) ?? user.displayName ?? '';
        if (data?['email'] is String) {
          _emailController.text = data!['email'] as String;
        }
      } catch (_) {
        _nameController.text = user.displayName ?? '';
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _image = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถเลือกรูปภาพได้'),
          backgroundColor: Color(0xFF1E3323),
        ),
      );
    }
  }

  // ป๊อปอัปเลือกที่มาของรูป
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'รูปโปรไฟล์',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3323),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSheetOption(
                  icon: Icons.photo_camera_outlined,
                  label: 'ถ่ายรูป',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSheetOption(
                  icon: Icons.photo_library_outlined,
                  label: 'เลือกจากคลังภาพ',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_image != null)
                  _buildSheetOption(
                    icon: Icons.delete_outline,
                    label: 'ลบรูปโปรไฟล์',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _image = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive ? const Color(0xFFEE4E4E) : const Color(0xFF1E3323);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFFDE8E8)
              : const Color(0xFFD7F5DC),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อ-สกุล')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // เก็บชื่อลง Firestore (หน้าโปรไฟล์ฟังค่านี้อยู่ จึงอัปเดตทันที)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'name': name}, SetOptions(merge: true));
        await user.updateDisplayName(name);
      }

      profileImageNotifier.value = _image;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกข้อมูลเรียบร้อย'),
          backgroundColor: Color(0xFF1E3323),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2), // พื้นหลังเขียวส่วนบน
      body: Column(
        children: [
          // 1. แถบ Header (มาตรฐานเดียวกับหน้าอื่น)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        'จัดการโปรไฟล์',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3323),
                          height: 1.2,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1E3323),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationPage(),
                            ),
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none,
                            color: Color(0xFF1E3323),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 2. ส่วนการ์ดโค้งมนคลุมพื้นที่ด้านล่างทั้งหมด
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF3FAF4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF1E3323)),
                      ),
                    )
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // รูปโปรไฟล์ + ปุ่มไอคอนกล้อง (กดที่รูปหรือกล้องก็ได้)
                    GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1E3323),
                                width: 3,
                              ),
                              color: Colors.white,
                            ),
                            child: ClipOval(
                              child: _image != null
                                  ? Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                      width: 94,
                                      height: 94,
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 70,
                                      color: Color(0xFF1E3323),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA2E0B2),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: Color(0xFF1E3323),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ชื่อแสดงใต้รูป
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _nameController,
                      builder: (context, value, _) {
                        final text = value.text.trim();
                        return Text(
                          text.isEmpty ? 'User' : text,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3323),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // หัวข้อ "ตั้งค่าบัญชีของฉัน"
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ตั้งค่าบัญชีของฉัน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3323),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ฟิลด์ ชื่อ
                    _buildInputField(
                      label: 'ชื่อผู้ใช้',
                      controller: _nameController,
                    ),

                    const SizedBox(height: 16),

                    // ฟิลด์ อีเมล
                    _buildInputField(
                      label: 'อีเมล',
                      controller: _emailController,
                      enabled: false, // อีเมลคือตัวที่ใช้ login จึงแก้ตรงนี้ไม่ได้
                    ),

                    const SizedBox(height: 35),

                    // ปุ่มบันทึก
                    SizedBox(
                      width: 160,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA2E0B2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1E3323),
                                  ),
                                ),
                              )
                            : const Text(
                                'บันทึก',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3323),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget สร้าง ช่องกรอกข้อมูล
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3323),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFE4F5E6), // สีเขียวอ่อนของช่องกรอก
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2E4032),
          ),
        ),
      ],
    );
  }
}