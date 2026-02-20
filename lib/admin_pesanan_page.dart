import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminPesananPage extends StatelessWidget {
  const AdminPesananPage({super.key});

  // FUNGSI CHAT: Mengirim notifikasi ke aplikasi user melalui koleksi Firestore
  Future<void> _chatUser(BuildContext context, String? userId, String namaKost) async {
    if (userId == null || userId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ID User tidak ditemukan")),
        );
      }
      return;
    }

    final TextEditingController pesanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kirim Pesan ke User", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: pesanController,
          decoration: const InputDecoration(
            hintText: "Tulis pesan Anda di sini...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("BATAL"),
          ),
          ElevatedButton(
            onPressed: () async {
              final isiPesan = pesanController.text.trim();
              if (isiPesan.isEmpty) return;

              try {
                // Menambahkan data ke koleksi notifications
                // Nantinya di aplikasi User, stream/listener akan menangkap ini
                await FirebaseFirestore.instance.collection('notifications').add({
                  'user_uid': userId,
                  'judul': 'Pesan dari Admin Kost',
                  'pesan': 'Terkait $namaKost: $isiPesan',
                  'is_read': false,
                  'tanggal': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pesan terkirim ke notifikasi user"),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal mengirim: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("KIRIM"),
          ),
        ],
      ),
    );
  }

  // FUNGSI EDIT MASA SEWA (Pilih Tanggal Baru)
  Future<void> _editMasaSewa(BuildContext context, String userUid, String namaKost) async {
    try {
      // Ambil data user dulu untuk mendapatkan tanggal berakhir saat ini
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userUid).get();
      
      // Safety check jika dokumen user atau field tanggal_berakhir tidak ada
      DateTime currentExpiry = DateTime.now();
      if (userDoc.exists && userDoc.data() != null) {
        var userData = userDoc.data() as Map<String, dynamic>;
        if (userData['tanggal_berakhir'] != null) {
          currentExpiry = (userData['tanggal_berakhir'] as Timestamp).toDate();
        }
      }

      if (!context.mounted) return;

      // Tampilkan DatePicker
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: currentExpiry.isBefore(DateTime.now()) ? DateTime.now() : currentExpiry,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 1825)), // +5 Tahun
        helpText: "Pilih Tanggal Berakhir Sewa Baru",
      );

      if (pickedDate != null) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userUid);
        
        batch.update(userRef, {
          'tanggal_berakhir': Timestamp.fromDate(pickedDate),
        });

        // Kirim notifikasi perubahan jadwal ke user
        DocumentReference notifyRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifyRef, {
          'user_uid': userUid,
          'judul': 'Update Masa Sewa',
          'pesan': 'Admin telah mengubah masa berakhir sewa $namaKost menjadi ${DateFormat('dd MMMM yyyy').format(pickedDate)}.',
          'is_read': false,
          'tanggal': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Masa sewa berhasil diperbarui!"), backgroundColor: Colors.blueAccent),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // FUNGSI HENTIKAN SEWA
  Future<void> _stopRental(BuildContext context, String docId, String userUid, String namaKost) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hentikan Sewa?"),
        content: Text("Status sewa user di $namaKost akan berakhir sekarang dan user bisa memesan kost lain."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("HENTIKAN SEKARANG", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        
        batch.update(FirebaseFirestore.instance.collection('pesanan').doc(docId), {
          'status': 'Selesai/Habis'
        });

        batch.update(FirebaseFirestore.instance.collection('users').doc(userUid), {
          'nama_kost_aktif': null,
          'tanggal_mulai': null,
          'tanggal_berakhir': null,
        });

        DocumentReference notifyRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifyRef, {
          'user_uid': userUid,
          'judul': 'Sewa Berakhir',
          'pesan': 'Masa sewa Anda di $namaKost telah dinyatakan berakhir oleh Admin.',
          'is_read': false,
          'tanggal': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sewa telah dihentikan.")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  // FUNGSI HAPUS PESANAN
  Future<void> _deleteOrder(BuildContext context, String docId, String? userUid) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Pesanan"),
        content: const Text("Apakah Anda yakin ingin menghapus data ini? Jika pesanan ini sedang aktif, status sewa user akan direset."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("BATAL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("HAPUS", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmDelete) {
      try {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        batch.delete(FirebaseFirestore.instance.collection('pesanan').doc(docId));

        if (userUid != null && userUid.isNotEmpty) {
          DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(userUid);
          batch.update(userRef, {
            'nama_kost_aktif': null,
            'tanggal_mulai': null,
            'tanggal_berakhir': null,
          });
        }

        await batch.commit();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pesanan dihapus & status user direset"), backgroundColor: Colors.black),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  // FUNGSI SETUJUI
  Future<void> _approveOrder(BuildContext context, String docId, Map<String, dynamic> dataPesanan) async {
    try {
      final String userUid = dataPesanan['user_id'] ?? ''; 
      final String namaKost = dataPesanan['nama_kost'] ?? 'Kost';
      
      if (userUid.isEmpty) throw "ID User tidak ditemukan.";

      DateTime sekarang = DateTime.now();
      DateTime berakhir = sekarang.add(const Duration(days: 30));

      WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.update(FirebaseFirestore.instance.collection('pesanan').doc(docId), {'status': 'Disetujui'});

      batch.update(FirebaseFirestore.instance.collection('users').doc(userUid), {
        'nama_kost_aktif': namaKost,
        'tanggal_mulai': Timestamp.fromDate(sekarang),
        'tanggal_berakhir': Timestamp.fromDate(berakhir),
      });

      DocumentReference notifyRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notifyRef, {
        'user_uid': userUid,
        'judul': 'Pesanan Disetujui!',
        'pesan': 'Selamat! Pesanan Anda di $namaKost telah disetujui. Masa sewa Anda telah aktif.',
        'is_read': false,
        'tanggal': Timestamp.fromDate(sekarang),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pesanan Disetujui!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // FUNGSI TOLAK
  Future<void> _rejectOrder(BuildContext context, String docId, String? userUid) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.update(FirebaseFirestore.instance.collection('pesanan').doc(docId), {'status': 'Ditolak'});

      if (userUid != null && userUid.isNotEmpty) {
        batch.update(FirebaseFirestore.instance.collection('users').doc(userUid), {'nama_kost_aktif': null});
      }

      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pesanan ditolak"), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Kelola Pesanan Masuk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pesanan')
            .orderBy('tanggal_pesan', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Terjadi kesalahan"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada pesanan masuk"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.58, 
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'Menunggu Konfirmasi';
              String userId = data['user_id'] ?? ''; 
              String namaKost = data['nama_kost'] ?? 'Kost';

              return Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(status),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () => _deleteOrder(context, doc.id, userId),
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        namaKost,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(),
                      _infoRow(Icons.person, data['user_email']?.split('@')[0] ?? "User"),
                      const SizedBox(height: 4),
                      _infoRow(Icons.payments, currencyFormatter.format(data['harga'] ?? 0)),
                      const SizedBox(height: 4),
                      _infoRow(Icons.calendar_today, data['tanggal_pesan'] != null 
                          ? DateFormat('dd/MM/yy').format((data['tanggal_pesan'] as Timestamp).toDate()) 
                          : '-'),
                      
                      const Spacer(),

                      // TOMBOL CHAT (Selalu Muncul)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => _chatUser(context, userId, namaKost),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("CHAT", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                      
                      const SizedBox(height: 5),
                      
                      // LOGIKA TOMBOL BERDASARKAN STATUS
                      if (status == 'Menunggu Konfirmasi')
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _approveOrder(context, doc.id, data),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("SETUJUI", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _rejectOrder(context, doc.id, userId),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red, 
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("TOLAK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      else if (status == 'Disetujui')
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _editMasaSewa(context, userId, namaKost),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("EDIT TANGGAL", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _stopRental(context, doc.id, userId, namaKost),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("HENTIKAN SEWA", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text, 
            style: const TextStyle(color: Colors.black87, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'Disetujui') color = Colors.green;
    if (status == 'Ditolak') color = Colors.red;
    if (status == 'Selesai/Habis') color = Colors.blueGrey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}