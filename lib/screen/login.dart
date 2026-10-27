import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/screen/home.dart';
import 'package:firstapp/screen/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 📌 แปลง error code ของ Firebase ให้เป็นข้อความภาษาไทยที่อ่านเข้าใจง่าย
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'too-many-requests':
        return 'ลองผิดหลายครั้งเกินไป กรุณาลองใหม่ภายหลัง';
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาลองใหม่';
      default:
        return 'เข้าสู่ระบบไม่สำเร็จ (${e.code})';
    }
  }

  // 📌 แปลง error ของการส่งอีเมลรีเซ็ตรหัสผ่าน
  String _mapResetError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'missing-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-not-found':
        return 'ไม่พบบัญชีที่ใช้อีเมลนี้';
      case 'too-many-requests':
        return 'ขอรีเซ็ตบ่อยเกินไป กรุณาลองใหม่ภายหลัง';
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาลองใหม่';
      default:
        return 'ส่งลิงก์รีเซ็ตรหัสผ่านไม่สำเร็จ (${e.code})';
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'กรุณากรอกอีเมลและรหัสผ่านให้ครบ');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      // ✅ เคลียร์ Stack ล้างหน้า Login ออกเมื่อเข้าสู่ระบบสำเร็จ
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorText = _mapAuthError(e));
    } catch (e) {
      setState(() => _errorText = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 📌 ลืมรหัสผ่าน: ส่งลิงก์ตั้งรหัสผ่านใหม่ไปทางอีเมล
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('กรอกอีเมลในช่องด้านบนก่อน แล้วกด "ลืมรหัสผ่าน?" อีกครั้ง');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnack(
        'ส่งลิงก์รีเซ็ตรหัสผ่านไปที่ $email แล้ว\n'
        'หากไม่พบในกล่องจดหมาย กรุณาตรวจสอบโฟลเดอร์สแปมด้วย',
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(_mapResetError(e));
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA8E0B3),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // ดึงความสูงให้พอดีหน้าจอ
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      const Text(
                        "ยินดีต้อนรับ",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF183B2D),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Container ด้านล่างให้ขยายเต็มพื้นที่ที่เหลือ
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 35,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(50),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "อีเมล",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 10),

                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: "example@example.com",
                                  filled: true,
                                  fillColor: const Color(0xFFD8EBD8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              const Text(
                                "รหัสผ่าน",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 10),

                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFD8EBD8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() =>
                                          _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
                              ),

                              // 📌 ข้อความ error (ถ้ามี)
                              if (_errorText != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  _errorText!,
                                  style: const TextStyle(
                                    color: Color(0xFFEE4E4E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],

                              const Spacer(), // ช่วยดันปุ่มลงไปด้านล่างอย่างเหมาะสม
                              /// ปุ่มเข้าสู่ระบบ
                              Center(
                                child: SizedBox(
                                  width: 180,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFA2E0B2),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _handleLogin,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.black87,
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            "เข้าสู่ระบบ",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              // 📌 ปุ่มลืมรหัสผ่าน (ใช้ TextButton ให้พื้นที่กดใหญ่ขึ้น)
                              Center(
                                child: TextButton(
                                  onPressed:
                                      _isLoading ? null : _handleForgotPassword,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text(
                                    "ลืมรหัสผ่าน?",
                                    style: TextStyle(
                                      color: Color(0xFF183B2D),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 9),

                              /// ปุ่มสร้างบัญชีใหม่
                              Center(
                                child: SizedBox(
                                  width: 180,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD8EBD8),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "สร้างบัญชีใหม่",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}