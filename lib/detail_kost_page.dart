import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DetailKostPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailKostPage({super.key, required this.data});

  // FUNGSI UNTUK MENGIRIM PESANAN KE FIRESTORE (INTEGRASI ADMIN)
  Future<void> _prosesPemesanan(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    // 1. Cek apakah user sudah login
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Silahkan login terlebih dahulu untuk memesan"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Simpan data ke koleksi 'pesanan'
      await FirebaseFirestore.instance.collection('pesanan').add({
        'kost_id': data['id'] ?? '',
        'nama_kost': data['nama_kost'] ?? 'Kost Tanpa Nama',
        'harga': data['harga'] ?? 0,
        'foto_kost': data['foto_kost'] ?? '',
        'user_id': user.uid,
        'user_email': user.email,
        'user_nama': user.displayName ?? 'Customer',
        'admin_id': data['admin_id'] ?? 'admin_umum',
        'status': 'Menunggu Konfirmasi',
        'tanggal_pesan': FieldValue.serverTimestamp(),
        // Menyimpan field tambahan agar saat dibuka dari riwayat, data tetap lengkap
        'jenis_kost': data['jenis_kost'] ?? 'Campur',
        'alamat': data['alamat'] ?? 'Lokasi tidak tersedia',
        'deskripsi': data['deskripsi'] ?? '',
        'fasilitas': data['fasilitas'] ?? [],
      });

      if (context.mounted) {
        Navigator.pop(context); // Tutup loading dialog

        // Tampilkan Sukses Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 10),
                Text("Berhasil!", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              "Permintaan Anda telah dikirim ke Admin.\nSilahkan cek menu Riwayat secara berkala.",
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    Navigator.pop(context); // Kembali ke Dashboard
                  },
                  child: const Text("TUTUP", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Tutup loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memesan: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    // Ambil daftar fasilitas dari data (jika ada)
    List<dynamic> fasilitas = data['fasilitas'] ?? [];
    
    // Cek apakah data ini datang dari koleksi 'pesanan' (punya status)
    bool isRiwayat = data.containsKey('status');
    String statusPesanan = data['status'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // HEADER: GAMBAR KOST
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.blueAccent,
            flexibleSpace: FlexibleSpaceBar(
              background: data['foto_kost'] != null && data['foto_kost'] != ""
                  ? Image.network(data['foto_kost'], fit: BoxFit.cover)
                  : Container(
                      color: Colors.blue[100],
                      child: const Icon(Icons.image, size: 100, color: Colors.blueAccent),
                    ),
            ),
          ),

          // KONTEN DETAIL
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Jenis & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          data['jenis_kost'] ?? "Campur",
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.orange, size: 24),
                          Text(" 4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Nama Kost
                  Text(
                    data['nama_kost'] ?? "Nama Kost",
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),

                  // Lokasi
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          data['alamat'] ?? "Lokasi tidak tersedia",
                          style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40, color: Color(0xFFF1F5F9)),

                  // Deskripsi
                  const Text("Deskripsi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    data['deskripsi'] ?? "Tidak ada deskripsi untuk kost ini.",
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 25),

                  // Fasilitas
                  const Text("Fasilitas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  fasilitas.isEmpty
                      ? const Text("Fasilitas standar tersedia", style: TextStyle(color: Colors.grey))
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: fasilitas.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(item.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 120), // Memberi ruang agar tidak tertutup BottomSheet
                ],
              ),
            ),
          ),
        ],
      ),

      // BOTTOM NAVIGATION: HARGA & TOMBOL PESAN / STATUS
      bottomSheet: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Harga Sewa", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  currencyFormatter.format(data['harga'] ?? 0),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const Text("/ bulan", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: isRiwayat
                  ? Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: statusPesanan == 'Disetujui' ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        statusPesanan.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusPesanan == 'Disetujui' ? Colors.green : Colors.orange,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => _prosesPemesanan(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Text(
                        "PESAN SEKARANG",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}