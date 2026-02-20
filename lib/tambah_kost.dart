import 'dart:io' show File; // Import terbatas agar tidak bentrok di web
import 'package:flutter/foundation.dart' show kIsWeb; // Penting untuk cek Web
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_kost/cloudinary_service.dart'; // Import service Cloudinary Anda

class TambahKostPage extends StatefulWidget {
  const TambahKostPage({super.key});

  @override
  State<TambahKostPage> createState() => _TambahKostPageState();
}

class _TambahKostPageState extends State<TambahKostPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _hargaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  
  // Field Baru untuk sinkronisasi filter
  String _selectedJenisKost = "Putra"; // Default value
  final List<String> _jenisKostOptions = ["Putra", "Putri", "Campur"];

  bool _isLoading = false;
  
  // Fitur Gambar
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];

  // Inisialisasi Service Cloudinary
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Fitur Fasilitas (Checkbox)
  final Map<String, bool> _fasilitasKamar = {
    "WiFi": false,
    "AC": false,
    "Kamar Mandi Dalam": false,
    "Kasur": false,
    "Lemari": false,
    "Meja Belajar": false,
    "Listrik Termasuk": false,
    "Air Panas": false,
  };

  final Map<String, bool> _fasilitasUmum = {
    "Dapur": false,
    "Parkir Motor": false,
    "Parkir Mobil": false,
    "CCTV": false,
    "Ruang Tamu": false,
    "Jemuran": false,
  };

  // Fungsi Toggle Select All
  void _toggleSelectAll(Map<String, bool> source, bool value) {
    setState(() {
      source.updateAll((key, oldVal) => value);
    });
  }

  // Fungsi ambil gambar gallery
  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _images.addAll(selectedImages);
      });
    }
  }

  // FUNGSI BARU: UPLOAD GAMBAR KE CLOUDINARY (PENGGANTI FIREBASE STORAGE)
  Future<List<String>> _uploadImagesToCloudinary() async {
    List<String> imageUrls = [];
    if (_images.isEmpty) return imageUrls;

    for (var i = 0; i < _images.length; i++) {
      // Mengambil path gambar, mendukung mobile & web (via library Cloudinary)
      String? downloadUrl = await _cloudinaryService.uploadImage(_images[i].path);
      
      if (downloadUrl != null) {
        imageUrls.add(downloadUrl);
      }
    }
    return imageUrls;
  }

  Future<void> _simpanKost() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // 1. Upload Gambar ke Cloudinary
        List<String> uploadedUrls = await _uploadImagesToCloudinary();

        // 2. Parsing harga
        int harga = int.tryParse(_hargaController.text.trim()) ?? 0;
        
        // 3. Mengumpulkan fasilitas
        List<String> fasilitasTerpilih = [];
        _fasilitasKamar.forEach((key, value) { if (value) fasilitasTerpilih.add(key); });
        _fasilitasUmum.forEach((key, value) { if (value) fasilitasTerpilih.add(key); });

        // 4. Simpan ke Firestore
        await FirebaseFirestore.instance.collection('data_kost').add({
          'nama_kost': _namaController.text.trim(),
          'alamat': _alamatController.text.trim(),
          'harga': harga,
          'jenis_kost': _selectedJenisKost, // SINKRON DENGAN FILTER DASHBOARD
          'deskripsi': _deskripsiController.text.trim(),
          'fasilitas': fasilitasTerpilih,
          'foto_urls': uploadedUrls, // List URL dari Cloudinary
          'foto_kost': uploadedUrls.isNotEmpty ? uploadedUrls[0] : null,
          'admin_id': FirebaseAuth.instance.currentUser?.uid,
          'created_at': Timestamp.now(),
          'jumlah_gambar': uploadedUrls.length,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data Kost Berhasil Ditambahkan!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Tambah Data Kost", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Foto Kost (Opsional - Pilih Beberapa)", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _images.length) {
                          return GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10, bottom: 5),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.blueAccent),
                              ),
                              child: const Icon(Icons.add_a_photo, color: Colors.blueAccent),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10, bottom: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: kIsWeb 
                                    ? NetworkImage(_images[index].path) 
                                    : FileImage(File(_images[index].path)) as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 15,
                              top: 5,
                              child: GestureDetector(
                                onTap: () => setState(() => _images.removeAt(index)),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 15, color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),

                  const Text("Informasi Dasar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _namaController,
                    label: "Nama Kost",
                    icon: Icons.business,
                    validator: (v) => v!.isEmpty ? "Nama tidak boleh kosong" : null,
                  ),
                  const SizedBox(height: 15),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedJenisKost,
                      decoration: const InputDecoration(
                        labelText: "Jenis Kost",
                        prefixIcon: Icon(Icons.people, color: Colors.blueAccent),
                        border: InputBorder.none,
                      ),
                      items: _jenisKostOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedJenisKost = newValue!;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _alamatController,
                    label: "Alamat Lengkap",
                    icon: Icons.location_on,
                    validator: (v) => v!.isEmpty ? "Alamat tidak boleh kosong" : null,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _hargaController,
                    label: "Harga per Bulan",
                    icon: Icons.payments,
                    keyboardType: TextInputType.number,
                    prefixText: "Rp ",
                    validator: (v) {
                      if (v!.isEmpty) return "Harga tidak boleh kosong";
                      if (int.tryParse(v) == null) return "Masukkan angka saja";
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _deskripsiController,
                    label: "Deskripsi Kost",
                    icon: Icons.description,
                    maxLines: 4,
                  ),
                  
                  const SizedBox(height: 25),

                  _buildSectionHeader("Fasilitas Kamar", _fasilitasKamar),
                  _buildCheckboxGrid(_fasilitasKamar),

                  const SizedBox(height: 15),
                  _buildSectionHeader("Fasilitas Umum", _fasilitasUmum),
                  _buildCheckboxGrid(_fasilitasUmum),

                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanKost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      child: _isLoading 
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 15),
                              Text("SEDANG MENYIMPAN...", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : const Text("SIMPAN DATA KOST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Map<String, bool> source) {
    bool isAllSelected = source.values.every((element) => element);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        TextButton.icon(
          onPressed: () => _toggleSelectAll(source, !isAllSelected),
          icon: Icon(isAllSelected ? Icons.check_box : Icons.check_box_outline_blank, size: 18),
          label: Text(isAllSelected ? "Hapus Semua" : "Pilih Semua", style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildCheckboxGrid(Map<String, bool> source) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200, 
        mainAxisExtent: 45, 
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemCount: source.length,
      itemBuilder: (context, index) {
        String key = source.keys.elementAt(index);
        return CheckboxListTile(
          title: Text(key, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
          value: source[key],
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (bool? value) {
            setState(() {
              source[key] = value!;
            });
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          prefixText: prefixText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}