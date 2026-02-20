import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// Pastikan path import ini sesuai dengan lokasi file DetailKostPage Anda
import 'detail_kost_page.dart'; 

class RiwayatPesananPage extends StatelessWidget {
  const RiwayatPesananPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Riwayat Pesanan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: user == null
          ? const Center(child: Text("Silahkan login terlebih dahulu"))
          : StreamBuilder<QuerySnapshot>(
              // Mengambil pesanan milik user yang sedang login
              stream: FirebaseFirestore.instance
                  .collection('pesanan')
                  .where('user_id', isEqualTo: user.uid)
                  .orderBy('tanggal_pesan', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Penanganan Error yang lebih spesifik untuk masalah Index
                if (snapshot.hasError) {
                  if (snapshot.error.toString().contains('failed-precondition')) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "Sedang menyiapkan database... (Indeks diperlukan). Jika ini pertama kali, harap tunggu beberapa menit atau klik link di log debug.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    );
                  }
                  return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("Belum ada riwayat pesanan", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    String status = data['status'] ?? 'Proses';
                    
                    // Warna badge status
                    Color statusColor = Colors.orange;
                    if (status == 'Disetujui') statusColor = Colors.green;
                    if (status == 'Ditolak') statusColor = Colors.red;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03), 
                            blurRadius: 10, 
                            offset: const Offset(0, 5)
                          )
                        ],
                      ),
                      // Membungkus dengan InkWell agar kartu bisa diklik
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // Navigasi ke DetailKostPage dengan membawa data pesanan
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailKostPage(data: data),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Foto Kost Kecil
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: data['foto_kost'] != null && data['foto_kost'] != ""
                                    ? Image.network(
                                        data['foto_kost'], 
                                        width: 80, 
                                        height: 80, 
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 80, height: 80, color: Colors.blue[50], child: const Icon(Icons.broken_image)
                                        ),
                                      )
                                    : Container(
                                        width: 80, 
                                        height: 80, 
                                        color: Colors.blue[50], 
                                        child: const Icon(Icons.home, color: Colors.blueAccent)
                                      ),
                              ),
                              const SizedBox(width: 16),
                              // Info Pesanan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['nama_kost'] ?? 'Nama Kost',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormatter.format(data['harga'] ?? 0),
                                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    // Badge Status
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Ikon indikator navigasi
                              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}