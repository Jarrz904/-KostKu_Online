import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PenghasilanPage extends StatelessWidget {
  const PenghasilanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Laporan Penghasilan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Kita hanya mengambil pesanan yang statusnya 'Disetujui'
        stream: FirebaseFirestore.instance
            .collection('pesanan')
            .where('status', isEqualTo: 'Disetujui')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Terjadi kesalahan data"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Menghitung total penghasilan secara dinamis
          double totalPenghasilan = 0;
          int totalTransaksi = snapshot.data!.docs.length;

          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            // Pastikan field 'harga' di Firestore adalah number (int/double)
            totalPenghasilan += (data['harga'] ?? 0).toDouble();
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Hijau untuk Total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
                      const SizedBox(height: 15),
                      const Text(
                        "Total Pendapatan Terakumulasi",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        currencyFormatter.format(totalPenghasilan),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$totalTransaksi Transaksi Berhasil",
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // List Detail Transaksi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: const [
                      Icon(Icons.history, size: 20, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        "Riwayat Transaksi Masuk",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    DateTime tgl = (data['tanggal_pesan'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                        ),
                        title: Text(
                          data['nama_kost'] ?? "Kost",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(tgl),
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          currencyFormatter.format(data['harga'] ?? 0),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}