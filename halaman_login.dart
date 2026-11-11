import 'package:firebase_auth/firebase_auth.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'halaman_daftar.dart';
import 'package:flutter/material.dart';

const Color warnaBackground = Color(0xFFEAF4FF);
const Color warnaNavy = Color(0xFF17365D);
const Color warnaPutih = Color(0xFFFFFFFF);
const Color warnaTeks = Color(0xFF171717);
const Color warnaAbu = Color(0xFF858B96);

class HalamanLogin extends StatefulWidget {
const HalamanLogin({super.key});

@override
State<HalamanLogin> createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin> {
final usernameController = TextEditingController();
final passwordController = TextEditingController();

bool sembunyikanPassword = true;

Future<void> masuk() async {
  final username = usernameController.text.trim().toLowerCase();
  final password = passwordController.text;

  if (username.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nama pengguna dan kata sandi wajib diisi.'),
      ),
    );
    return;
  }

  try {
    final emailInternal = '$username@catatanmakanan.app';

    final hasilLogin =
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailInternal,
      password: password,
    );

    final user = hasilLogin.user;

    if (user == null) {
      throw Exception('Akun tidak ditemukan.');
    }

    // Simpan profil pengguna di Firestore.
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login berhasil!'),
      ),
    );
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.code == 'invalid-credential' ||
              e.code == 'wrong-password' ||
              e.code == 'user-not-found'
              ? 'Nama pengguna atau kata sandi salah.'
              : 'Login gagal: ${e.message ?? e.code}',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal menyimpan profil: $e'),
      ),
    );
  }
}


@override
void dispose() {
usernameController.dispose();
passwordController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: warnaBackground,
body: SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(28),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const Icon(
Icons.restaurant_menu,
size: 76,
color: warnaNavy,
),

const SizedBox(height: 20),

const Text(
'Catatan Makanan',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
color: warnaNavy,
),
),

const SizedBox(height: 8),

const Text(
'Catat makananmu dengan mudah',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 14,
color: warnaAbu,
),
),

const SizedBox(height: 36),

TextField(
controller: usernameController,
decoration: InputDecoration(
labelText: 'Nama Pengguna',
prefixIcon: const Icon(
Icons.person_outline,
color: warnaNavy,
),
filled: true,
fillColor: warnaPutih,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide.none,
),
),
),

const SizedBox(height: 16),

TextField(
controller: passwordController,
obscureText: sembunyikanPassword,
decoration: InputDecoration(
labelText: 'Kata Sandi',
prefixIcon: const Icon(
Icons.lock_outline,
color: warnaNavy,
),
suffixIcon: IconButton(
onPressed: () {
setState(() {
sembunyikanPassword = !sembunyikanPassword;
});
},
icon: Icon(
sembunyikanPassword
? Icons.visibility_off
    : Icons.visibility,
color: warnaAbu,
),
),
filled: true,
fillColor: warnaPutih,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide.none,
),
),
),

const SizedBox(height: 24),

SizedBox(
height: 52,
child: ElevatedButton(
  onPressed: masuk,
style: ElevatedButton.styleFrom(
backgroundColor: warnaNavy,
foregroundColor: warnaPutih,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: const Text(
'Masuk',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
),
),

const SizedBox(height: 16),

Center(
child: TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HalamanDaftar(),
      ),
    );
  },
  child: const Text(
    'Belum punya akun? Daftar',
    style: TextStyle(
      color: warnaNavy,
      fontWeight: FontWeight.w600,
    ),
  ),
),
),
],
),
),
),
),
);
}
}