import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'user_dashboard.dart';

// 1. ANIMASI LOADING (SPLASH SCREEN) - VERSI KUNCI & PINTU TERBUKA
class LoadingSplashScreen extends StatefulWidget {
  const LoadingSplashScreen({super.key});

  @override
  State<LoadingSplashScreen> createState() => _LoadingSplashScreenState();
}

class _LoadingSplashScreenState extends State<LoadingSplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _keyRotate;
  late Animation<double> _doorOpen;
  late Animation<double> _contentZoom;
  late Animation<double> _doorOpacity;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // 1. Animasi Kunci Memutar (0.0 - 0.2)
    _keyRotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.2, curve: Curves.easeInOut)),
    );

    // 2. Animasi Pintu Terbuka (0.2 - 0.5) - Kita buat lebih lambat agar terlihat
    _doorOpen = Tween<double>(begin: 0, end: -1.6).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.5, curve: Curves.easeInCirc)),
    );

    // 3. Animasi Zoom In Masuk ke Ruangan (0.4 - 1.0)
    _contentZoom = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn)),
    );

    // 4. Opacity Pintu (0.5 - 0.7)
    _doorOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.5, 0.7, curve: Curves.easeOut)),
    );

    _mainController.forward();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkLoginStatus();
      }
    });
  }

  void _checkLoginStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      // Menggunakan transisi Fade yang sangat halus setelah pintu terbuka lebar
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1200),
          pageBuilder: (context, anim, _) => FadeTransition(
            opacity: anim, 
            child: user != null ? const UserDashboard() : const LandingPage()
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1), // Warna dasar ruangan dalam
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          // Opacity ruangan dalam (muncul perlahan saat pintu terbuka)
          double roomOpacity = (_mainController.value > 0.2) 
              ? ((_mainController.value - 0.2) * 2.5).clamp(0.0, 1.0) 
              : 0.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              // --- LAPISAN 1: RUANGAN DI DALAM PINTU ---
              Transform.scale(
                scale: _contentZoom.value,
                child: Opacity(
                  opacity: roomOpacity,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF0D47A1)],
                        radius: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.home_work_rounded, size: 100, color: Colors.white),
                          const SizedBox(height: 20),
                          Text(
                            "KostKu",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9), 
                              fontSize: 32, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- LAPISAN 2: VISUAL PINTU ---
              if (_doorOpacity.value > 0.001)
                Opacity(
                  opacity: _doorOpacity.value,
                  child: Container(
                    color: const Color(0xFF0D47A1), // Background pintu agar ruangan dalam tidak bocor sebelum terbuka
                    alignment: Alignment.center,
                    child: Transform(
                      alignment: Alignment.centerLeft, // Pintu engsel di kiri
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015) // Perspektif 3D
                        ..rotateY(_doorOpen.value),
                      child: Container(
                        width: 260,
                        height: 450,
                        decoration: BoxDecoration(
                          color: Colors.brown[800],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.brown[900]!, width: 10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6), 
                              blurRadius: 30, 
                              spreadRadius: 5
                            )
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            // Detail Panel Pintu
                            Positioned.fill(
                              child: Container(
                                margin: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.brown[900]!.withOpacity(0.5), width: 2),
                                ),
                              ),
                            ),
                            // Gagang Pintu & Kunci
                            Positioned(
                              right: 25,
                              child: Column(
                                children: [
                                  Container(
                                    width: 12, height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.amber[600], 
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4)]
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Transform.rotate(
                                    angle: _keyRotate.value * pi * 2,
                                    child: Icon(Icons.vpn_key_rounded, color: Colors.amber[400], size: 45),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// 2. LANDING PAGE
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _startAnimation = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF1976D2), Color(0xFF0D47A1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          ...List.generate(8, (index) => const FloatingParticle()),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 1000),
                      opacity: _startAnimation ? 1.0 : 0.0,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.home_work_rounded, size: 80, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "KostKu",
                            style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    AnimatedTransform(
                      active: _startAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Column(
                          children: [
                            Text("Solusi Hunian Modern", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                            SizedBox(height: 10),
                            Text(
                              "Temukan ribuan pilihan kost strategis, nyaman, dan transparan dalam satu genggaman.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    AnimatedTransform(
                      active: _startAnimation,
                      child: Column(
                        children: [
                          _buildButton(context, "MASUK KE AKUN", Colors.white, Colors.blueAccent, 
                            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()))),
                          const SizedBox(height: 15),
                          _buildOutlineButton(context, "DAFTAR SEKARANG", 
                            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Color bg, Color textCol, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: textCol, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOutlineButton(BuildContext context, String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 55,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class FloatingParticle extends StatefulWidget {
  const FloatingParticle({super.key});
  @override
  State<FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<FloatingParticle> {
  late double top, left, size;
  late Duration duration;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    top = random.nextDouble() * 600;
    left = random.nextDouble() * 300;
    size = random.nextDouble() * 30 + 10;
    duration = Duration(seconds: random.nextInt(4) + 6);
    WidgetsBinding.instance.addPostFrameCallback((_) => updateParticle());
  }

  void updateParticle() {
    if (!mounted) return;
    setState(() {
      top = random.nextDouble() * 800;
      left = random.nextDouble() * 400;
      duration = Duration(seconds: random.nextInt(4) + 8);
    });
    Future.delayed(duration, updateParticle);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: duration, curve: Curves.easeInOutSine, top: top, left: left,
      child: IgnorePointer(
        child: AnimatedOpacity(duration: const Duration(seconds: 3), opacity: 0.1, child: const Icon(Icons.home_rounded, color: Colors.white)),
      ),
    );
  }
}

class AnimatedTransform extends StatelessWidget {
  final Widget child;
  final bool active;
  const AnimatedTransform({super.key, required this.child, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutExpo,
      transform: Matrix4.translationValues(0, active ? 0 : 60, 0),
      child: AnimatedOpacity(duration: const Duration(milliseconds: 1000), opacity: active ? 1.0 : 0.0, child: child),
    );
  }
}