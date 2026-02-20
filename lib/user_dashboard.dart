import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'cloudinary_service.dart'; 

// Import file widget
import 'widgets/hero_carousel.dart';
import 'widgets/greeting_header.dart';
import 'widgets/kost_card.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/quick_categories.dart';
import 'login_page.dart';
import 'riwayat_pesanan_page.dart';
import 'notification_page.dart'; 

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _activePage = 0;
  Timer? _timer;
  
  String _sectionTitle = "Rekomendasi Kost Terbaru";

  late Stream<QuerySnapshot> _kostStream;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final List<Map<String, String>> _heroImages = [
    {
      "image": "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=1000",
      "title": "Promo Awal Tahun!",
      "sub": "Diskon kost hingga 20%"
    },
    {
      "image": "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?q=80&w=1000",
      "title": "Kost Eksklusif Nyaman",
      "sub": "Fasilitas lengkap"
    },
    {
      "image": "https://images.unsplash.com/photo-1554995207-c18c203602cb?q=80&w=1000",
      "title": "Cari Kost Lebih Mudah",
      "sub": "Ribuan pilihan"
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyFilter("");
    _updateOnlineStatus(true); // Set Online saat masuk dashboard

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_activePage < _heroImages.length - 1) ? _activePage + 1 : 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          // Perbaikan typo kurva dari kode asli
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  // Fungsi update status tanpa memicu offline saat navigasi internal
  void _updateOnlineStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'is_online': isOnline,
        'last_online': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  Future<void> _handleRefresh() async {
    _applyFilter(_searchController.text);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _applyFilter(String value, {bool isCategory = false}) {
    setState(() {
      Query query = FirebaseFirestore.instance.collection('data_kost');
      
      if (value.isEmpty || value == "Semua") {
        _sectionTitle = "Rekomendasi Kost Terbaru";
        _kostStream = query.orderBy('created_at', descending: true).snapshots();
      } else if (isCategory) {
        _sectionTitle = "Kost Kategori: $value";
        if (value == "Murah") {
          _kostStream = query.where('harga', isLessThanOrEqualTo: 1000000).snapshots();
        } else if (value == "Eksklusif") {
          _kostStream = query.where('harga', isGreaterThan: 2500000).snapshots();
        } else if (value == "Putri") {
          _kostStream = query.where('jenis_kost', isEqualTo: 'Putri').snapshots();
        } else if (value == "Putra") {
          _kostStream = query.where('jenis_kost', isEqualTo: 'Putra').snapshots();
        }
      } else {
        _sectionTitle = "Hasil Pencarian: '$value'";
        _kostStream = query
            .where('nama_kost', isGreaterThanOrEqualTo: value)
            .where('nama_kost', isLessThanOrEqualTo: '$value\uf8ff')
            .snapshots();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'is_online': false,
          'last_online': FieldValue.serverTimestamp(),
        });
      }
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Gagal logout: $e");
    }
  }

  void _openChatAdmin() async {
    const phone = "6285741129749";
    const message = "Halo Admin KostKu, saya ingin bertanya mengenai kost...";
    final url = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}");
    final fallbackUrl = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak dapat membuka WhatsApp")));
      }
    }
  }

  Future<void> _checkAndSendExpiryNotification(String uid, int sisaHari, String namaKost) async {
    if (sisaHari <= 3 && sisaHari >= 0) {
      final now = DateTime.now();
      final String dailyNotifId = "${uid}_expiry_${now.year}${now.month}${now.day}";
      final docRef = FirebaseFirestore.instance.collection('notifications').doc(dailyNotifId);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'user_uid': uid, 
          'judul': 'Masa Sewa Hampir Habis!',
          'pesan': 'Masa sewa Anda di $namaKost sisa $sisaHari hari lagi.',
          'is_read': false,
          'tanggal': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _showPerpanjangDialog(String uid, DateTime currentExpiry, String namaKost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Perpanjang Kost", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin memperpanjang masa kost selama 30 hari?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              DateTime newExpiry = currentExpiry.add(const Duration(days: 30));
              WriteBatch batch = FirebaseFirestore.instance.batch();
              DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
              batch.update(userRef, {'tanggal_berakhir': Timestamp.fromDate(newExpiry)});
              DocumentReference notifRef = FirebaseFirestore.instance.collection('notifications').doc();
              batch.set(notifRef, {
                'user_uid': uid, 
                'judul': 'Perpanjangan Berhasil',
                'pesan': 'Sewa kost $namaKost berhasil diperpanjang.',
                'is_read': false,
                'tanggal': FieldValue.serverTimestamp(),
              });
              await batch.commit();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil diperpanjang!")));
              }
            },
            child: const Text("Ya, Perpanjang", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRentalStatus(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
        
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        // Logika diperbaiki: pastikan field ada dan tidak kosong
        if (userData['tanggal_mulai'] == null || 
            userData['tanggal_berakhir'] == null || 
            userData['nama_kost_aktif'] == null ||
            userData['nama_kost_aktif'].toString().isEmpty) {
          return const SizedBox.shrink();
        }

        DateTime start = (userData['tanggal_mulai'] as Timestamp).toDate();
        DateTime end = (userData['tanggal_berakhir'] as Timestamp).toDate();
        String namaKost = userData['nama_kost_aktif'] ?? "Kost Anda";

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home_work_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(namaKost, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    const Text("Sewa Aktif", style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDateColumn("Mulai Kost", start, Icons.calendar_today_rounded, Colors.green),
                    Container(height: 30, width: 1, color: Colors.grey[200]),
                    _buildDateColumn("Berakhir Kost", end, Icons.event_busy_rounded, Colors.redAccent),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateColumn(String title, DateTime date, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 5),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd MMM yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildAdminBroadcast() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pengumuman')
          .where('is_active', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.purple.shade700]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data['pesan'] ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusAnnouncement(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        
        // Cek apakah ada sewa aktif sebelum menampilkan pengumuman sisa hari
        if (userData['tanggal_berakhir'] == null || 
            userData['nama_kost_aktif'] == null || 
            userData['nama_kost_aktif'].toString().isEmpty) {
          return const SizedBox.shrink();
        }

        DateTime end = (userData['tanggal_berakhir'] as Timestamp).toDate();
        int sisaHari = end.difference(DateTime.now()).inDays;
        String namaKost = userData['nama_kost_aktif'] ?? "Kost";

        _checkAndSendExpiryNotification(uid, sisaHari, namaKost);
        if (sisaHari > 7) return const SizedBox.shrink();

        Color themeColor = sisaHari <= 3 ? Colors.redAccent : Colors.orangeAccent;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeColor.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active, color: themeColor),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Masa Kost Hampir Habis", style: TextStyle(fontWeight: FontWeight.bold, color: themeColor)),
                        Text(sisaHari < 0 ? "Masa sewa Anda telah berakhir." : "Sisa $sisaHari hari lagi.", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  onPressed: () => _showPerpanjangDialog(uid, end, namaKost),
                  child: const Text("Perpanjang", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _editProfileDialog(String uid, Map<String, dynamic> userData) {
    final namaController = TextEditingController(text: userData['nama']);
    String? currentFotoUrl = userData['foto_url'];
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: const Text("Edit Profil Saya", style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    final picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                    if (image != null) {
                      setDialogState(() => isUploading = true);
                      String? uploadedUrl = await _cloudinaryService.uploadImage(image.path);
                      setDialogState(() {
                        if (uploadedUrl != null) currentFotoUrl = uploadedUrl;
                        isUploading = false;
                      });
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: (currentFotoUrl != null && currentFotoUrl!.isNotEmpty) ? NetworkImage(currentFotoUrl!) : null,
                        child: (currentFotoUrl == null || currentFotoUrl!.isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                      ),
                      if (isUploading) const CircleAvatar(radius: 40, backgroundColor: Colors.black26, child: CircularProgressIndicator(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: namaController,
                  decoration: InputDecoration(
                    labelText: "Nama Lengkap",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: isUploading ? null : () async {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'nama': namaController.text.trim(),
                    'foto_url': currentFotoUrl,
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("KostKu", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent)),
        leading: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('notifications').where('user_uid', isEqualTo: user?.uid).snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              unreadCount = snapshot.data!.docs.where((doc) => (doc.data() as Map<String, dynamic>)['is_read'] == false).length;
            }
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.blueAccent),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage())),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(unreadCount > 9 ? '9+' : '$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPesananPage())), icon: const Icon(Icons.receipt_long_rounded, color: Colors.blueAccent)),
          IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout_rounded, color: Colors.redAccent)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChatAdmin,
        backgroundColor: const Color(0xFF25D366),
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text("Chat Admin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh, 
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), 
          child: Column(
            children: [
              GreetingHeader(user: user, onEditProfile: (uid, userData) => _editProfileDialog(uid, userData)),
              HeroCarousel(controller: _pageController, images: _heroImages, activePage: _activePage, onPageChanged: (page) => setState(() => _activePage = page)),
              _buildAdminBroadcast(),
              if (user != null) _buildActiveRentalStatus(user.uid),
              if (user != null) _buildStatusAnnouncement(user.uid),
              SearchBarWidget(controller: _searchController, onChanged: (value) => _applyFilter(value)),
              QuickCategories(onCategoryTap: (category) => _applyFilter(category, isCategory: true)),
              _buildSectionTitle(),
              _buildKostListStream(),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_sectionTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => _applyFilter(""),
            child: const Text(
              "Lihat Semua",
              style: TextStyle(
                fontSize: 14, 
                color: Colors.blueAccent, 
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKostListStream() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        bool hasActiveRental = false;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          // PERBAIKAN DI SINI:
          // Tombol terkunci HANYA jika 'nama_kost_aktif' ada dan tidak kosong.
          hasActiveRental = userData['nama_kost_aktif'] != null && 
                           userData['nama_kost_aktif'].toString().trim().isNotEmpty;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _kostStream, 
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Kost tidak ditemukan"));

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: snapshot.data!.docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                var data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                
                return KostCard(
                  nama: data['nama_kost'] ?? "-",
                  lokasi: data['alamat'] ?? "-",
                  harga: data['harga'] ?? 0,
                  fotoKost: data['foto_kost'],
                  fullData: data,
                  isDisabled: hasActiveRental, 
                );
              },
            );
          },
        );
      },
    );
  }
}