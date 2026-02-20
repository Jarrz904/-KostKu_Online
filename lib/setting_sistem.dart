import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingSistemPage extends StatefulWidget {
  const SettingSistemPage({super.key});

  @override
  State<SettingSistemPage> createState() => _SettingSistemPageState();
}

class _SettingSistemPageState extends State<SettingSistemPage> {
  final msgCtrl = TextEditingController();
  
  // State untuk fitur tambahan
  String _selectedLanguage = 'Bahasa Indonesia';
  bool _maintenanceMode = false;
  bool _notificationStatus = true;

  final List<String> _languages = [
    'Bahasa Indonesia',
    'English',
    'Melayu',
    '日本語 (Japanese)',
    'العربية (Arabic)'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Pengaturan Sistem", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: BROADCAST PENGUMUMAN (DENGAN FCM NOTIFIKASI) ---
            const Text(
              "Broadcast Pengumuman",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 5),
            const Text(
              "Pesan akan muncul di dashboard & notifikasi push HP semua user.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: TextField(
                controller: msgCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Tulis pengumuman baru di sini...",
                  hintStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _prosesBroadcast(),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text("Broadcast Sekarang", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // --- BAGIAN 2: FITUR SETTING LAINNYA ---
            const Text(
              "Konfigurasi Global",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),

            // Card Pengaturan Bahasa
            _buildSettingCard(
              icon: Icons.language_rounded,
              title: "Bahasa Default Sistem",
              subtitle: "Pilih bahasa utama aplikasi",
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguage = newValue!;
                  });
                },
                items: _languages.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
              ),
            ),

            // Switch Mode Pemeliharaan
            _buildSettingCard(
              icon: Icons.construction_rounded,
              title: "Mode Pemeliharaan",
              subtitle: "Nonaktifkan akses user sementara",
              trailing: Switch(
                value: _maintenanceMode,
                activeColor: Colors.purple,
                onChanged: (val) {
                  setState(() {
                    _maintenanceMode = val;
                  });
                },
              ),
            ),

            // Switch Notifikasi Push
            _buildSettingCard(
              icon: Icons.notifications_active_rounded,
              title: "Notifikasi Push",
              subtitle: "Kirim alert otomatis saat ada pesanan",
              trailing: Switch(
                value: _notificationStatus,
                activeColor: Colors.purple,
                onChanged: (val) {
                  setState(() {
                    _notificationStatus = val;
                  });
                },
              ),
            ),

            const SizedBox(height: 30),

            // --- BAGIAN 3: RIWAYAT PENGUMUMAN ---
            const Text(
              "Riwayat Pengumuman",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pengumuman')
                  .orderBy('timestamp', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF3E5F5),
                          child: Icon(Icons.campaign, color: Colors.purple, size: 20),
                        ),
                        title: Text(doc['pesan'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          "Status: ${doc['is_active'] ? 'Aktif' : 'Nonaktif'}",
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => doc.reference.delete(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),
            
            // Info Versi Aplikasi
            Center(
              child: Column(
                children: [
                  Text("Versi Aplikasi v2.0.4-Production", 
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  const SizedBox(height: 20),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Baris Pengaturan
  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.purple, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  // Fungsi Broadcast yang diperbarui untuk mendukung Notifikasi All Users
  Future<void> _prosesBroadcast() async {
    if (msgCtrl.text.trim().isEmpty) return;

    // Tampilkan loading
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final String pesanBroad = msgCtrl.text.trim();
      final DateTime sekarang = DateTime.now();

      // 1. Simpan ke koleksi 'pengumuman' untuk dashboard aplikasi
      await FirebaseFirestore.instance.collection('pengumuman').add({
        'pesan': pesanBroad,
        'timestamp': FieldValue.serverTimestamp(),
        'is_active': true,
        'tipe': 'info',
      });

      // 2. Kirim Notifikasi ke koleksi 'notifications' untuk setiap user
      // Ini agar muncul di halaman notifikasi masing-masing user
      final userSnap = await FirebaseFirestore.instance.collection('users').get();
      
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var userDoc in userSnap.docs) {
        DocumentReference notifyRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifyRef, {
          'user_uid': userDoc.id,
          'judul': 'Pengumuman Baru',
          'pesan': pesanBroad,
          'is_read': false,
          'tanggal': Timestamp.fromDate(sekarang),
          'type': 'broadcast'
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Pengumuman & Notifikasi berhasil disebarkan ke semua user!"),
          backgroundColor: Colors.green,
        ));
        msgCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal broadcast: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}