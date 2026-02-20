import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class DaftarKostAktifPage extends StatelessWidget {
  const DaftarKostAktifPage({super.key});

  // --- FUNGSI VIEW DETAIL ---
  void _viewKost(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: data['foto_kost'] != null && data['foto_kost'] != ""
                    ? Image.network(
                        data['foto_kost'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.home, size: 50),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(data['nama_kost'] ?? "-",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(data['jenis_kost'] ?? "Campur",
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text("Harga: Rp ${data['harga']} / Bulan",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text("Alamat:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(data['alamat'] ?? '-', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 10),
                    const Text("Deskripsi:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(data['deskripsi'] ?? '-', style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
        ],
      ),
    );
  }

  // --- FUNGSI DELETE ---
  void _deleteKost(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Kost"),
        content: const Text("Apakah Anda yakin ingin menghapus data kost ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('data_kost').doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI EDIT (UPDATE) ---
  void _editKost(BuildContext context, String docId, Map<String, dynamic> data) {
    final namaCtrl = TextEditingController(text: data['nama_kost']);
    final hargaCtrl = TextEditingController(text: data['harga'].toString());
    final deskripsiCtrl = TextEditingController(text: data['deskripsi']);
    final alamatCtrl = TextEditingController(text: data['alamat']);
    XFile? newImage;
    final picker = ImagePicker();
    bool isUploading = false; // Untuk status loading

    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa asal klik luar saat upload
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Data Kost"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final img = await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) setState(() => newImage = img);
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      image: newImage != null
                          ? DecorationImage(
                              image: kIsWeb ? NetworkImage(newImage!.path) : FileImage(File(newImage!.path)) as ImageProvider,
                              fit: BoxFit.cover)
                          : (data['foto_kost'] != null && data['foto_kost'] != ""
                              ? DecorationImage(image: NetworkImage(data['foto_kost']), fit: BoxFit.cover)
                              : null),
                    ),
                    child: newImage == null && (data['foto_kost'] == null || data['foto_kost'] == "")
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : (newImage != null ? const Align(alignment: Alignment.bottomRight, child: Padding(padding: EdgeInsets.all(8), child: Icon(Icons.check_circle, color: Colors.green))) : null),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: "Nama Kost")),
                TextField(controller: hargaCtrl, decoration: const InputDecoration(labelText: "Harga"), keyboardType: TextInputType.number),
                TextField(controller: alamatCtrl, decoration: const InputDecoration(labelText: "Alamat")),
                TextField(controller: deskripsiCtrl, decoration: const InputDecoration(labelText: "Deskripsi"), maxLines: 3),
                if (isUploading) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(),
                  const Text("Sedang mengupdate data...", style: TextStyle(fontSize: 12)),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context), 
              child: const Text("Batal")
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                setState(() => isUploading = true);
                
                try {
                  String? url = data['foto_kost'];
                  
                  // Proses Upload ke Storage jika ada gambar baru yang dipilih
                  if (newImage != null) {
                    var ref = FirebaseStorage.instance.ref().child('kost/${DateTime.now().millisecondsSinceEpoch}.jpg');
                    
                    if (kIsWeb) {
                      await ref.putData(await newImage!.readAsBytes());
                    } else {
                      await ref.putFile(File(newImage!.path));
                    }
                    url = await ref.getDownloadURL();
                  }

                  // Proses Update ke Firestore
                  await FirebaseFirestore.instance.collection('data_kost').doc(docId).update({
                    'nama_kost': namaCtrl.text,
                    'harga': int.tryParse(hargaCtrl.text) ?? 0,
                    'alamat': alamatCtrl.text,
                    'deskripsi': deskripsiCtrl.text,
                    'foto_kost': url,
                  });

                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setState(() => isUploading = false);
                  // Tambahkan snackbar jika error
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal update: $e"))
                    );
                  }
                }
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Daftar Kost Aktif", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('data_kost').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada data kost aktif"));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => _viewKost(context, data),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: data['foto_kost'] != null && data['foto_kost'] != ""
                                  ? Image.network(
                                      data['foto_kost'],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.blue[50],
                                      child: const Icon(Icons.home, size: 50, color: Colors.blue),
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(data['jenis_kost'] ?? "Kost",
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['nama_kost'] ?? "Kost",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Rp ${data['harga']} / Bulan",
                                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                    onPressed: () => _editKost(context, doc.id, data),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteKost(context, doc.id),
                                  ),
                                ),
                              ],
                            )
                          ],
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
}