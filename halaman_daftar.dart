
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'halaman_login.dart';

class HalamanDaftar extends StatefulWidget {
const HalamanDaftar({super.key});

@override
State<HalamanDaftar> createState() => _HalamanDaftarState();
}

class _HalamanDaftarState extends State<HalamanDaftar> {
final usernameController = TextEditingController();
final passwordController = TextEditingController();
final konfirmasiPasswordController = TextEditingController();

bool sembunyikanPassword = true;
bool sedangMemuat = false;

Future<void> daftar() async {
final username = usernameController.text.trim().toLowerCase();
final password = passwordController.text;
final konfirmasiPassword = konfirmasiPasswordController.text;

if (username.isEmpty ||
password.isEmpty ||
konfirmasiPassword.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Semua kolom wajib diisi.'),
),
);
return;
}

if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Nama pengguna harus 3–20 karakter: huruf kecil, angka, atau _.',
),
),
);
return;
}

if (password.length < 6) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Kata sandi minimal 6 karakter.'),
),
);
return;
}

if (password != konfirmasiPassword) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Konfirmasi kata sandi tidak cocok.'),
),
);
return;
}

setState(() {
sedangMemuat = true;
});

try {
final emailInternal = '$username@catatanmakanan.app';

final hasil = await FirebaseAuth.instance
    .createUserWithEmailAndPassword(
email: emailInternal,
password: password,
);

final user = hasil.user;

if (user == null) {
throw Exception('Akun tidak berhasil dibuat.');
}

await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .set({
'username': username,
'createdAt': FieldValue.serverTimestamp(),
});

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Pendaftaran berhasil! Silakan masuk.'),
),
);

Navigator.pop(context);
} on FirebaseAuthException catch (e) {
if (!mounted) return;

String pesan = 'Pendaftaran gagal. Silakan coba lagi.';

if (e.code == 'email-already-in-use') {
pesan = 'Nama pengguna sudah digunakan.';
} else if (e.code == 'weak-password') {
pesan = 'Kata sandi terlalu lemah.';
} else if (e.code == 'invalid-email') {
pesan = 'Nama pengguna tidak valid.';
}

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(pesan)),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Akun mungkin sudah dibuat, tetapi profil gagal disimpan. Periksa koneksi dan Firebase.',
),
),
);
} finally {
if (mounted) {
setState(() {
sedangMemuat = false;
});
}
}
}

@override
void dispose() {
usernameController.dispose();
passwordController.dispose();
konfirmasiPasswordController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: warnaBackground,
appBar: AppBar(
backgroundColor: warnaBackground,
foregroundColor: warnaNavy,
elevation: 0,
title: const Text('Buat Akun'),
),
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const Icon(
Icons.person_add_alt_1,
size: 68,
color: warnaNavy,
),
const SizedBox(height: 16),
const Text(
'Daftar Akun Baru',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 25,
fontWeight: FontWeight.bold,
color: warnaNavy,
),
),
const SizedBox(height: 8),
const Text(
'Buat akun untuk mulai mencatat makanan.',
textAlign: TextAlign.center,
style: TextStyle(color: warnaAbu),
),
const SizedBox(height: 32),
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
const SizedBox(height: 16),
TextField(
controller: konfirmasiPasswordController,
obscureText: true,
decoration: InputDecoration(
labelText: 'Konfirmasi Kata Sandi',
prefixIcon: const Icon(
Icons.lock_reset,
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
const SizedBox(height: 24),
SizedBox(
height: 52,
child: ElevatedButton(
onPressed: sedangMemuat ? null : daftar,
style: ElevatedButton.styleFrom(
backgroundColor: warnaNavy,
foregroundColor: warnaPutih,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: sedangMemuat
? const CircularProgressIndicator(
color: warnaPutih,
)
    : const Text(
'Daftar',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
),
),
const SizedBox(height: 16),
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text(
'Sudah punya akun? Masuk',
style: TextStyle(
color: warnaNavy,
fontWeight: FontWeight.w600,
),
),
),
],
),
),
),
);
}
}