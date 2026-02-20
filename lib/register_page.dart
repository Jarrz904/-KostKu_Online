import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // Controller Baru untuk WA
  bool _isLoading = false;
  bool _obscureText = true;

  // FUNGSI REGISTRASI
  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim(); // Ambil input WA

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      _showSnackBar("Semua kolom harus diisi!", Colors.orangeAccent);
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Password minimal 6 karakter!", Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Buat User di Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Simpan data tambahan ke Firestore
      // Menggunakan field yang sinkron dengan dashboard admin (is_active, last_seen, dll)
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'nama': name,
        'email': email,
        'whatsapp': phone,
        'password': password, // Disimpan agar Admin bisa menghapus akun via TempApp
        'role': 'user',
        'is_active': true, // SET KE TRUE agar user langsung aktif setelah registrasi
        'last_seen': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'foto_url': '',
        'nama_kost_aktif': '',
      });

      if (mounted) {
        _showSnackBar("Registrasi Berhasil! Silakan Login.", Colors.green);
        Navigator.pop(context); // Kembali ke LoginPage
      }
    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan";
      if (e.code == 'email-already-in-use') {
        message = "Email sudah digunakan akun lain.";
      } else if (e.code == 'invalid-email') {
        message = "Format email tidak valid.";
      } else if (e.code == 'weak-password') {
        message = "Password terlalu lemah.";
      }
      if (mounted) _showSnackBar(message, Colors.redAccent);
    } catch (e) {
      if (mounted) _showSnackBar("Gagal Daftar: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose(); // Dispose controller WA
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFF1976D2), Color(0xFF0D47A1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Dekorasi Background (Lingkaran)
            Positioned(
              top: -50,
              left: -50,
              child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.white.withOpacity(0.05)),
            ),
            Positioned(
              bottom: -30,
              right: -30,
              child: CircleAvatar(
                  radius: 80, backgroundColor: Colors.white.withOpacity(0.05)),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Icon Header
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.person_add_rounded,
                              size: 60, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Buat Akun",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1),
                      ),
                      const Text(
                        "Daftar untuk mulai mencari kostan",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 40),

                      // FORM REGISTRASI
                      _buildInputField(
                        controller: _nameController,
                        label: "Nama Lengkap",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      
                      // Input WhatsApp
                      _buildInputField(
                        controller: _phoneController,
                        label: "Nomor WhatsApp",
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      // KETERANGAN WHATSAPP
                      const Padding(
                        padding: EdgeInsets.only(top: 8, left: 4, right: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "* Nomor WhatsApp wajib diisi untuk memudahkan pemilik kost menghubungi Anda terkait ketersediaan kamar.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      _buildInputField(
                        controller: _emailController,
                        label: "Email Address",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        controller: _passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 40),

                      // Tombol Daftar
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.2),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: CircularProgressIndicator(
                                    color: Colors.blueAccent,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text("DAFTAR SEKARANG",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Link Kembali ke Login
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: RichText(
                          text: const TextSpan(
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                            children: [
                              TextSpan(text: "Sudah punya akun? "),
                              TextSpan(
                                text: "Masuk di sini",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
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
      ),
    );
  }

  // Widget Helper Input Field
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}