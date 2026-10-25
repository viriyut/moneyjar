import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/screen/edit_profile_screen.dart' show profileImageNotifier;
import 'package:firstapp/screen/notification.dart';
import 'package:firstapp/screen/started.dart';
import 'package:firstapp/screen/tutorial.dart';
import 'package:firstapp/services/app_setting.dart';
import 'package:firstapp/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  /// เรียกตอนกดปุ่มย้อนกลับ (ถ้าไม่ส่งมา จะ fallback ไปใช้ Navigator.pop ตามปกติ)
  final VoidCallback? onBack;

  /// เรียกเมื่อผู้ใช้กดยืนยันลบบัญชี
  final VoidCallback? onDeleteAccount;

  const SettingsScreen({super.key, this.onBack, this.onDeleteAccount});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 📌 สถานะเปิด/ปิดการแจ้งเตือน (อ่านจากค่ากลางที่หน้าหลักโหลดมาจาก Firestore)
  bool _notificationEnabled = notificationsEnabledNotifier.value;

  Future<void> _setNotificationEnabled(bool value) async {
    setState(() => _notificationEnabled = value);
    notificationsEnabledNotifier.value = value; // หน้าหลักอ่านค่านี้ก่อนยิงแจ้งเตือน

    // เปิด/ปิดแจ้งเตือนรายวัน (ตั้งเวลาใหม่ หรือยกเลิกที่ตั้งไว้)
    try {
      await NotificationService.setDailyReminderEnabled(value);
    } catch (_) {}

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'notificationsEnabled': value}, SetOptions(merge: true));
    } catch (_) {
      _showSnack('บันทึกการตั้งค่าไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
    }
  }

  // ============================================================
  // 📌 ป๊อปอัปตั้งค่ารหัสผ่านใหม่
  // ============================================================
  void _showChangePasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        String? errorText;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD7F5DC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.vpn_key_outlined,
                          color: Color(0xFF1E3323),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'ตั้งค่ารหัสผ่าน',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3323),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: oldController,
                        hint: 'รหัสผ่านเดิม',
                      ),
                      const SizedBox(height: 10),
                      _buildPasswordField(
                        controller: newController,
                        hint: 'รหัสผ่านใหม่',
                      ),
                      const SizedBox(height: 10),
                      _buildPasswordField(
                        controller: confirmController,
                        hint: 'ยืนยันรหัสผ่านใหม่',
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFEE4E4E),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF1E3323),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'ยกเลิก',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3323),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: const Color(0xFFA2E0B2),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                if (oldController.text.isEmpty ||
                                    newController.text.isEmpty) {
                                  setDialogState(
                                    () => errorText = 'กรุณากรอกข้อมูลให้ครบ',
                                  );
                                  return;
                                }
                                if (newController.text.length < 6) {
                                  setDialogState(
                                    () => errorText =
                                        'รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร',
                                  );
                                  return;
                                }
                                if (newController.text !=
                                    confirmController.text) {
                                  setDialogState(
                                    () => errorText = 'รหัสผ่านใหม่ไม่ตรงกัน',
                                  );
                                  return;
                                }

                                final user = FirebaseAuth.instance.currentUser;
                                final email = user?.email;
                                if (user == null || email == null) {
                                  setDialogState(
                                    () => errorText = 'ไม่พบบัญชีที่เข้าสู่ระบบอยู่',
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isSaving = true;
                                  errorText = null;
                                });

                                try {
                                  // ยืนยันรหัสผ่านเดิมก่อน แล้วค่อยเปลี่ยนเป็นรหัสผ่านใหม่
                                  await user.reauthenticateWithCredential(
                                    EmailAuthProvider.credential(
                                      email: email,
                                      password: oldController.text,
                                    ),
                                  );
                                  await user.updatePassword(newController.text);

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _showSnack('เปลี่ยนรหัสผ่านเรียบร้อย');
                                } on FirebaseAuthException catch (e) {
                                  String msg;
                                  switch (e.code) {
                                    case 'wrong-password':
                                    case 'invalid-credential':
                                      msg = 'รหัสผ่านเดิมไม่ถูกต้อง';
                                      break;
                                    case 'weak-password':
                                      msg = 'รหัสผ่านใหม่ไม่ปลอดภัยพอ';
                                      break;
                                    case 'too-many-requests':
                                      msg = 'ลองผิดหลายครั้งเกินไป กรุณาลองใหม่ภายหลัง';
                                      break;
                                    case 'network-request-failed':
                                      msg = 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาลองใหม่';
                                      break;
                                    default:
                                      msg = 'เปลี่ยนรหัสผ่านไม่สำเร็จ (${e.code})';
                                  }
                                  if (ctx.mounted) {
                                    setDialogState(() {
                                      isSaving = false;
                                      errorText = msg;
                                    });
                                  }
                                } catch (_) {
                                  if (ctx.mounted) {
                                    setDialogState(() {
                                      isSaving = false;
                                      errorText = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
                                    });
                                  }
                                }
                              },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3323),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF3FAF4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ============================================================
  // 📌 ลบบัญชีจริง: ยืนยันรหัสผ่านซ้ำ -> ลบข้อมูลใน Firestore -> ลบบัญชี Firebase
  // ============================================================
  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ลบธุรกรรมทั้งหมด (ทีละชุด เพราะ Firestore ลบ subcollection ให้เองไม่ได้) แล้วลบเอกสารผู้ใช้
  Future<void> _deleteUserData(String uid) async {
    final db = FirebaseFirestore.instance;
    final userDoc = db.collection('users').doc(uid);

    while (true) {
      final snap = await userDoc.collection('transactions').limit(400).get();
      if (snap.docs.isEmpty) break;
      final batch = db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await userDoc.delete();
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      _showSnack('ไม่พบบัญชีที่เข้าสู่ระบบอยู่');
      return;
    }

    // Firebase บังคับให้ยืนยันตัวตนซ้ำก่อนลบบัญชี จึงขอรหัสผ่านอีกครั้ง
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _PasswordPromptDialog(),
    );
    if (password == null || password.isEmpty || !mounted) return;

    bool loadingOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
    void closeLoading() {
      if (loadingOpen && mounted) {
        loadingOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      await _deleteUserData(user.uid);
      await user.delete();
      profileImageNotifier.value = null; // ล้างรูปโปรไฟล์ที่ค้างอยู่ในหน่วยความจำ

      closeLoading();
      if (!mounted) return;
      _showSnack('ลบบัญชีเรียบร้อยแล้ว');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StartedScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      closeLoading();
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showSnack('รหัสผ่านไม่ถูกต้อง');
      } else if (e.code == 'too-many-requests') {
        _showSnack('ลองผิดหลายครั้งเกินไป กรุณาลองใหม่ภายหลัง');
      } else if (e.code == 'network-request-failed') {
        _showSnack('เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาลองใหม่');
      } else {
        _showSnack('ลบบัญชีไม่สำเร็จ (${e.code})');
      }
    } catch (e) {
      closeLoading();
      _showSnack('ลบบัญชีไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
    }
  }

  // ============================================================
  // 📌 ป๊อปอัปยืนยันลบบัญชีผู้ใช้ (สีแดง)
  // ============================================================
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDE8E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_remove_outlined,
                    color: Color(0xFFEE4E4E),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ลบบัญชีผู้ใช้',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3323),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ข้อมูลทั้งหมดของคุณจะถูกลบถาวร\nและไม่สามารถกู้คืนได้',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF1E3323)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3323),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFEE4E4E),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (widget.onDeleteAccount != null) {
                            widget.onDeleteAccount!();
                          } else {
                            _deleteAccount();
                          }
                        },
                        child: const Text(
                          'ลบบัญชี',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---------- Header ----------
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        'ตั้งค่า',
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
                        onTap: () {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
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
            const SizedBox(height: 14),

            // ---------- การ์ดขาวด้านล่าง ----------
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3FAF4),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      // 1) ตั้งค่าการแจ้งเตือน (มี Switch)
                      _buildSettingItem(
                        icon: Icons.notifications_none,
                        title: 'ตั้งค่าการแจ้งเตือน',
                        trailing: Switch(
                          value: _notificationEnabled,
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF4CD080),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey[300],
                          onChanged: (val) => _setNotificationEnabled(val),
                        ),
                        onTap: () =>
                            _setNotificationEnabled(!_notificationEnabled),
                      ),
                      const SizedBox(height: 12),

                      // วิธีใช้งานแอป (เปิดดู tutorial ซ้ำได้)
                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: 'วิธีใช้งานแอป',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TutorialScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // 2) ตั้งค่ารหัสผ่าน
                      _buildSettingItem(
                        icon: Icons.vpn_key_outlined,
                        title: 'ตั้งค่ารหัสผ่าน',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                        onTap: _showChangePasswordDialog,
                      ),
                      const SizedBox(height: 12),

                      // 3) ลบบัญชีผู้ใช้
                      _buildSettingItem(
                        icon: Icons.person_remove_outlined,
                        title: 'ลบบัญชีผู้ใช้',
                        iconBgColor: const Color(0xFFFDE8E8),
                        iconColor: const Color(0xFFEE4E4E),
                        isDestructive: true,
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFEE4E4E),
                          size: 24,
                        ),
                        onTap: _showDeleteAccountDialog,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- แถวรายการตั้งค่า 1 แถว (สไตล์เดียวกับเมนูหน้าโปรไฟล์) ----------
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
    Color iconBgColor = const Color(0xFFD7F5DC),
    Color iconColor = const Color(0xFF1E3323),
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDestructive
                        ? const Color(0xFFEE4E4E)
                        : const Color(0xFF1E3323),
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// 📌 หน้าต่างให้กรอกรหัสผ่านเพื่อยืนยันตัวตนก่อนลบบัญชี
// ============================================================
class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog();

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ยืนยันตัวตน',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3323),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'กรอกรหัสผ่านเพื่อยืนยันการลบบัญชี',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'รหัสผ่าน',
                filled: true,
                fillColor: const Color(0xFFF3FAF4),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF1E3323)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3323),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFEE4E4E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, _controller.text),
                    child: const Text(
                      'ลบบัญชี',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}