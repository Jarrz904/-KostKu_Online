import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // FUNGSI LOGIN UTAMA
  Future<void> _login() async {
    // Validasi Input Sederhana
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showSnackBar("Email dan Password wajib diisi!", Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Proses Sign In ke Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Ambil Data Role dari Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'];
        if (mounted) {
          // Navigasi Berdasarkan Role
          // Gunakan pushAndRemoveUntil agar user tidak bisa 'Back' ke halaman login lagi
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => role == 'admin' ? const AdminDashboard() : const UserDashboard(),
            ),
            (route) => false,
          );
        }
      } else {
        // Jika akun ada di Auth tapi tidak ada di Firestore
        if (mounted) {
          _showSnackBar("Data role akun tidak ditemukan!", Colors.redAccent);
        }
      }
    } on FirebaseAuthException catch (e) {
      // Penanganan Error yang Lebih User-Friendly
      String message = "Terjadi kesalahan sistem";
      if (e.code == 'user-not-found') {
        message = "Email tidak terdaftar.";
      } else if (e.code == 'wrong-password') {
        message = "Password salah.";
      } else if (e.code == 'invalid-email') {
        message = "Format email salah.";
      } else if (e.code == 'user-disabled') {
        message = "Akun ini telah dinonaktifkan.";
      }
      
      if (mounted) _showSnackBar(message, Colors.redAccent);
    } catch (e) {
      if (mounted) _showSnackBar("Gagal masuk: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper untuk menampilkan SnackBar
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan extendBodyBehindAppBar agar gradient memenuhi layar
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
            // Dekorasi Lingkaran Latar Belakang
            Positioned(
              top: -30,
              right: -30,
              child: CircleAvatar(
                radius: 80, 
                backgroundColor: Colors.white.withOpacity(0.05)
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: CircleAvatar(
                radius: 100, 
                backgroundColor: Colors.white.withOpacity(0.05)
              ),
            ),
            
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header Icon
                    Hero(
                      tag: 'app_logo', // Tag hero agar animasi sinkron dengan Landing Page
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.home_work_rounded, size: 70, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      "Masuk untuk melanjutkan",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 50),

                    // Input Email
                    _buildGlassTextField(
                      controller: _emailController,
                      label: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    // Input Password
                    _buildGlassTextField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: !_isPasswordVisible,
                      toggleVisibility: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                    ),
                    
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Tambahkan navigasi lupa password jika diperlukan
                        }, 
                        child: const Text("Lupa Password?", style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Tombol Login
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
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
                            : const Text(
                                "LOGIN", 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Belum punya akun?", style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          child: const Text(
                            "Daftar Sekarang",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper Glassmorphism
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? toggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
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
                    obscureText ? Icons.visibility_off : Icons.visibility, 
                    color: Colors.white70
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}