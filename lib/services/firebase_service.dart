import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ดึง User ปัจจุบัน
  User? get currentUser => _auth.currentUser;

  // 1. สมัครสมาชิกด้วย Email & Password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 2. เข้าสู่ระบบ
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // 3. ออกจากระบบ
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. บันทึกธุรกรรมใหม่ไปยัง Firestore
  Future<void> addTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required DateTime dateTime,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .add({
      'title': title,
      'amount': amount,
      'isIncome': isIncome,
      'dateTime': Timestamp.fromDate(dateTime),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 5. ดึง Stream ข้อมูลธุรกรรมทั้งหมดของผู้ใช้ (เรียงตามเวลา)
  Stream<List<Map<String, dynamic>>> getTransactionsStream() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
          'isIncome': data['isIncome'] ?? false,
          'dateTime': (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }
}