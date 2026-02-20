import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GreetingHeader extends StatelessWidget {
  final User? user;
  final Function(String, Map<String, dynamic>) onEditProfile;

  const GreetingHeader({super.key, required this.user, required this.onEditProfile});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // Stream ini akan memantau perubahan dokumen user di Firestore secara realtime
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String displayName = user?.email?.split('@')[0] ?? 'User';
        String? fotoUrl;
        Map<String, dynamic> rawData = {};

        if (snapshot.hasData && snapshot.data!.exists) {
          rawData = snapshot.data!.data() as Map<String, dynamic>;
          displayName = rawData['nama'] ?? displayName;
          // fotoUrl ini berisi link HTTPS dari Cloudinary yang disimpan di Firestore
          fotoUrl = rawData['foto_url'];
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sapaan dipercantik dengan Label Kategori
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "🏠 PREMIUM USER",
                            style: TextStyle(
                              fontSize: 9, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.blueAccent,
                              letterSpacing: 1
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Nama User dengan Gaya Tipografi Elegan
                    Text(
                      "Selamat Datang,",
                      style: TextStyle(
                        fontSize: 14, 
                        color: Colors.blueGrey.withOpacity(0.7), 
                        fontWeight: FontWeight.w400
                      ),
                    ),
                    Text(
                      "$displayName 👋",
                      style: const TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.w900, 
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Siap menemukan hunian impianmu?",
                      style: TextStyle(
                        fontSize: 13, 
                        color: Colors.blueGrey.withOpacity(0.5),
                        fontWeight: FontWeight.w400
                      ),
                    ),
                  ],
                ),
              ),
              // Bagian Foto Profil (Hasil Upload Cloudinary)
              GestureDetector(
                onTap: () => onEditProfile(user!.uid, rawData),
                child: Hero(
                  tag: 'profile_pic',
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent,
                          Colors.blueAccent.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 30, // Sedikit diperbesar agar foto terlihat jelas
                        backgroundColor: const Color(0xFFF1F5F9),
                        // Menggunakan NetworkImage untuk memuat URL Cloudinary yang tersimpan di Firestore
                        backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty) 
                            ? NetworkImage(fotoUrl) 
                            : null,
                        child: (fotoUrl == null || fotoUrl.isEmpty)
                            ? const Icon(Icons.person_rounded, size: 32, color: Colors.blueAccent)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}