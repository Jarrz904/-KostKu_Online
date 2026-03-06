import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  // FUNGSI LOGIN UTAMA (EMAIL/PASS)
  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showSnackBar("Email dan Password wajib diisi!", Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'];
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => role == 'admin' ? const AdminDashboard() : const UserDashboard(),
            ),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          _showSnackBar("Data role akun tidak ditemukan!", Colors.redAccent);
        }
      }
    } on FirebaseAuthException catch (e) {
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

  // FUNGSI GOOGLE SIGN IN (DIPERBAIKI DENGAN AUTO-REGISTER LENGKAP)
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        DocumentSnapshot userDoc = await userRef.get();

        // JIKA BELUM ADA, BUAT DOKUMEN DENGAN STRUKTUR LENGKAP
        if (!userDoc.exists) {
          await userRef.set({
            'uid': user.uid,
            'nama': user.displayName ?? "User Google",
            'email': user.email,
            'role': 'user',
            'whatsapp': '',
            'foto_url': user.photoURL ?? '',
            'is_active': true,
            'is_online': true,
            'nama_kost_aktif': '',
            'password': '', // Google login biasanya tidak menyimpan password teks
            'created_at': FieldValue.serverTimestamp(),
            'last_online': FieldValue.serverTimestamp(),
            'last_seen': FieldValue.serverTimestamp(),
          });
        }

        // Ambil data terbaru untuk navigasi
        DocumentSnapshot finalUserDoc = await userRef.get();
        String role = finalUserDoc['role'] ?? 'user';

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => role == 'admin' ? const AdminDashboard() : const UserDashboard()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar("Gagal Login Google: $e", Colors.redAccent);
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
            Positioned(top: -30, right: -30, child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.05))),
            Positioned(bottom: 100, left: -50, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05))),
            
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'app_logo',
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
                    const Text("Welcome Back!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                    const Text("Masuk untuk melanjutkan", style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 50),

                    _buildGlassTextField(controller: _emailController, label: "Email Address", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    _buildGlassTextField(
                      controller: _passwordController, label: "Password", icon: Icons.lock_outline, isPassword: true, obscureText: !_isPasswordVisible,
                      toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5),
                        child: _isLoading ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 3)) : const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text("ATAU", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png', height: 24),
                        label: const Text("Masuk dengan Google", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Belum punya akun?", style: TextStyle(color: Colors.white70)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                          child: const Text("Daftar Sekarang", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildGlassTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, bool obscureText = false, TextInputType keyboardType = TextInputType.text, VoidCallback? toggleVisibility}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.2))),
      child: TextField(
        controller: controller, obscureText: obscureText, keyboardType: keyboardType, style: const TextStyle(color: Colors.white), cursorColor: Colors.white,
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.white70), prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: isPassword ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white70), onPressed: toggleVisibility) : null,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}