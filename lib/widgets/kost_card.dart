import 'package:flutter/material.dart';
import '../detail_kost_page.dart'; 

class KostCard extends StatelessWidget {
  final String nama;
  final String lokasi;
  final dynamic harga;
  final String? fotoKost;
  final double rating;
  final int totalReviews;
  final Map<String, dynamic> fullData;
  final bool isDisabled; // Parameter untuk mengunci akses

  const KostCard({
    super.key,
    required this.nama,
    required this.lokasi,
    required this.harga,
    required this.fullData,
    this.fotoKost,
    this.rating = 4.8,
    this.totalReviews = 12,
    this.isDisabled = false, // Default bernilai false (tersedia)
  });

  @override
  Widget build(BuildContext context) {
    // Format harga ke Rupiah (titik sebagai pemisah ribuan)
    String formattedHarga = harga.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

    void goToDetail() {
      // Jika isDisabled true, munculkan pesan peringatan
      if (isDisabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kost ini sedang tidak tersedia atau Anda memiliki sewa aktif."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailKostPage(data: fullData),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(2), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: goToDetail, // Tetap aktifkan fungsi agar bisa memunculkan SnackBar saat isDisabled
            child: Opacity(
              opacity: isDisabled ? 0.7 : 1.0, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BAGIAN GAMBAR
                  Stack(
                    children: [
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          image: (fotoKost != null && fotoKost!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(fotoKost!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (fotoKost == null || fotoKost!.isEmpty)
                            ? const Icon(Icons.home_work_rounded,
                                size: 30, color: Colors.blueAccent)
                            : null,
                      ),
                      // Badge Status di Pojok Kiri Atas Gambar
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isDisabled ? Icons.lock_clock : Icons.check_circle, 
                                color: isDisabled ? Colors.orange : Colors.green, 
                                size: 8
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isDisabled ? "Terisi" : "Tersedia", // Diubah dari 'Terkunci' jadi 'Terisi' agar lebih natural
                                style: TextStyle(
                                    color: isDisabled ? Colors.orange : Colors.green,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // BAGIAN KONTEN
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // INFO ATAS: Nama & Lokasi
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nama,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1E293B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
                                  const SizedBox(width: 2),
                                  Text(rating.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.location_on_rounded, size: 10, color: Colors.redAccent),
                                  Expanded(
                                    child: Text(
                                      lokasi,
                                      style: const TextStyle(color: Colors.blueGrey, fontSize: 9),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // INFO BAWAH: Harga & Tombol
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Mulai dari", style: TextStyle(color: Colors.grey, fontSize: 9)),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                        text: "Rp $formattedHarga",
                                        style: const TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14)),
                                    const TextSpan(
                                        text: "/bln",
                                        style: TextStyle(color: Colors.grey, fontSize: 9)),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                height: 30,
                                child: ElevatedButton(
                                  onPressed: goToDetail, // Panggil goToDetail agar SnackBar tetap muncul saat diklik
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDisabled ? Colors.grey.shade300 : Colors.blueAccent,
                                    foregroundColor: isDisabled ? Colors.grey : Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    isDisabled ? "Penuh" : "Pesan Sekarang", // Perubahan teks agar tidak hardcoded 'Sewa Aktif'
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)
                                  ),
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
          ),
        ),
      ),
    );
  }
}