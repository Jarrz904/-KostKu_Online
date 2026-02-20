import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import dashboard untuk mengakses ChatPage
import 'admin_dashboard.dart'; 

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set status online saat user membuka halaman notifikasi
    _updateOnlineStatus(true);
  }

  @override
  void dispose() {
    // Set status ke offline saat widget dihancurkan
    _updateOnlineStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // SINKRONISASI STATUS
  void _updateOnlineStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'is_online': isOnline,
          'is_active': isOnline, 
          'last_online': FieldValue.serverTimestamp(),
          'last_seen': FieldValue.serverTimestamp(), 
        });
      } catch (e) {
        debugPrint("Error update status: $e");
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Perbaikan logika: Menyesuaikan status berdasarkan siklus hidup aplikasi secara presisi
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive || 
               state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  // NAVIGASI KE CHAT
  void _navigateToInternalChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ChatPage(), 
        ),
      );
    }
  }

  // Menghapus satu notifikasi
  Future<void> _hapusNotifikasi(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
    } catch (e) {
      debugPrint("Gagal menghapus notifikasi: $e");
    }
  }

  // Menghapus semua notifikasi personal
  Future<void> _deleteAllNotifications(String uid) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('user_uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Semua notifikasi berhasil dibersihkan")),
        );
      }
    } catch (e) {
      debugPrint("Error delete all: $e");
    }
  }

  void _showDeleteAllDialog(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Hapus Semua"),
        content: const Text("Hapus semua riwayat notifikasi Anda? Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllNotifications(uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Tandai sebagai dibaca
  Future<void> _markAsRead(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(docId).update({
        'is_read': true,
      });
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Notifikasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              onPressed: () => _showDeleteAllDialog(user.uid),
              tooltip: "Bersihkan Semua",
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToInternalChat,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text("Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: user == null
          ? const Center(child: Text("Silahkan login terlebih dahulu"))
          : StreamBuilder<QuerySnapshot>(
              // Filter: Mengambil notifikasi milik user UID tersebut ATAU broadcast ('all')
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('user_uid', whereIn: [user.uid, 'all'])
                  .orderBy('tanggal', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    String judul = data['judul'] ?? 'Notifikasi';
                    String pesan = data['pesan'] ?? '-';
                    bool isRead = data['is_read'] ?? false;
                    Timestamp? ts = data['tanggal'] as Timestamp?;
                    
                    // Default Icon & Color
                    IconData iconData = Icons.notifications_none_rounded;
                    Color themeColor = Colors.blueAccent;

                    // Logika penentuan icon berdasarkan Judul atau Type
                    final judulLower = judul.toLowerCase();
                    if (judulLower.contains('pengumuman') || judulLower.contains('broadcast')) {
                      iconData = Icons.campaign_rounded;
                      themeColor = Colors.purple;
                    } else if (judulLower.contains('disetujui') || judulLower.contains('berhasil')) {
                      iconData = Icons.check_circle_rounded;
                      themeColor = Colors.green;
                    } else if (judulLower.contains('ditolak') || judulLower.contains('gagal')) {
                      iconData = Icons.cancel_rounded;
                      themeColor = Colors.redAccent;
                    } else if (judulLower.contains('pesan') || judulLower.contains('chat')) {
                      iconData = Icons.forum_rounded;
                      themeColor = Colors.orange;
                    }

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) => _hapusNotifikasi(doc.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400, 
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          // Jika belum dibaca, beri background sangat tipis agar beda
                          color: isRead ? Colors.white : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                          border: isRead 
                              ? Border.all(color: Colors.transparent)
                              : Border.all(color: themeColor.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (!isRead) _markAsRead(doc.id);
                            
                            if (judulLower.contains('pesan') || 
                                judulLower.contains('chat')) {
                                _navigateToInternalChat();
                            }
                          },
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: themeColor.withOpacity(0.1),
                                child: Icon(iconData, color: themeColor, size: 22),
                              ),
                              if (!isRead)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            judul,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              color: isRead ? Colors.black87 : Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                pesan,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isRead ? Colors.grey[600] : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ts != null 
                                    ? DateFormat('dd MMM, HH:mm').format(ts.toDate()) 
                                    : "-",
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "Belum ada notifikasi",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            Text(
              "Gagal Memuat Data\n$error",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}