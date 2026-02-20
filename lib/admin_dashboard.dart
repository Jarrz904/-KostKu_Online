import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Tambahan untuk JSON
import 'package:http/http.dart' as http; // Tambahan untuk kirim API notifikasi

// Import file fitur lainnya
import 'login_page.dart';
import 'tambah_kost.dart';
import 'kelola_user.dart';
import 'penghasilan.dart';
import 'setting_sistem.dart';
import 'daftar_kost_aktif.dart';
import 'admin_pesanan_page.dart';

// --- HALAMAN CHAT GLOBAL ---
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Internal"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var users = snapshot.data!.docs.where((doc) => doc.id != currentUser?.uid).toList();

          if (users.isEmpty) {
            return const Center(child: Text("Tidak ada pengguna lain ditemukan"));
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              var userData = users[index].data() as Map<String, dynamic>;
              bool isActive = userData['is_active'] ?? false;
              String userId = users[index].id;
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .where('receiverId', isEqualTo: currentUser?.uid)
                    .where('senderId', isEqualTo: userId)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, msgSnapshot) {
                  int unreadCount = msgSnapshot.data?.docs.length ?? 0;

                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          backgroundImage: (userData['foto_url'] != null && userData['foto_url'].toString().isNotEmpty) 
                              ? NetworkImage(userData['foto_url']) 
                              : const AssetImage('assets/images/logo.png') as ImageProvider,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(userData['nama'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(isActive ? "Online" : "Offline", style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 12)),
                    trailing: unreadCount > 0 
                      ? Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text("$unreadCount", style: const TextStyle(color: Colors.white, fontSize: 10)),
                        )
                      : const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            receiverId: userId,
                            receiverName: userData['nama'] ?? "User",
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// --- HALAMAN DETAIL PESAN (DENGAN NOTIFIKASI) ---
class ChatDetailScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  const ChatDetailScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String currentId = FirebaseAuth.instance.currentUser!.uid;
  bool _showStickers = false;

  String getChatId() {
    List<String> ids = [currentId, widget.receiverId];
    ids.sort();
    return ids.join("_");
  }

  void _markAsRead() async {
    var query = await FirebaseFirestore.instance
        .collection('messages')
        .where('chatId', isEqualTo: getChatId())
        .where('receiverId', isEqualTo: currentId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  // Fungsi Kirim Notifikasi FCM
  Future<void> _sendNotification(String receiverId, String msg) async {
    try {
      // Ambil token FCM penerima dari Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(receiverId).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        String? token = data['fcmToken']; 

        if (token != null && token.isNotEmpty) {
          await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'key=YOUR_SERVER_KEY_HERE', // GANTI DENGAN SERVER KEY FIREBASE ANDA
            },
            body: jsonEncode({
              'to': token,
              'notification': {
                'title': 'Pesan Baru dari Admin',
                'body': msg,
                'sound': 'default',
              },
              'data': {
                'type': 'chat',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            }),
          );
        }
      }
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  final List<String> stickers = [
    "https://cdn-icons-png.flaticon.com/512/4721/4721118.png",
    "https://cdn-icons-png.flaticon.com/512/4721/4721092.png",
    "https://cdn-icons-png.flaticon.com/512/4721/4721102.png",
    "https://cdn-icons-png.flaticon.com/512/4721/4721109.png",
    "https://cdn-icons-png.flaticon.com/512/4721/4721115.png",
    "https://cdn-icons-png.flaticon.com/512/4721/4721121.png",
  ];

  void _sendMessage({String? text, String? stickerUrl}) async {
    if ((text == null || text.trim().isEmpty) && stickerUrl == null) return;
    
    String messageContent = text ?? "Mengirim Stiker";
    String type = stickerUrl != null ? 'sticker' : 'text';

    if (text != null) _msgController.clear();
    if (stickerUrl != null) setState(() => _showStickers = false);

    await FirebaseFirestore.instance.collection('messages').add({
      'chatId': getChatId(),
      'senderId': currentId,
      'receiverId': widget.receiverId,
      'message': messageContent,
      'stickerUrl': stickerUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'isRead': false,
      'users': [currentId, widget.receiverId],
    });

    _sendNotification(widget.receiverId, messageContent);
  }

  @override
  Widget build(BuildContext context) {
    _markAsRead();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('chatId', isEqualTo: getChatId())
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentId;
                    bool isRead = data['isRead'] ?? false;
                    String type = data['type'] ?? 'text';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            padding: type == 'sticker' ? EdgeInsets.zero : const EdgeInsets.all(12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                            decoration: BoxDecoration(
                              color: type == 'sticker' ? Colors.transparent : (isMe ? Colors.blueAccent : Colors.grey[300]),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(15),
                                topRight: const Radius.circular(15),
                                bottomLeft: Radius.circular(isMe ? 15 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 15),
                              ),
                            ),
                            child: type == 'sticker' 
                                ? Image.network(data['stickerUrl'], width: 100, height: 100)
                                : Text(data['message'], style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                          ),
                          if (isMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 12, bottom: 4),
                              child: Icon(
                                isRead ? Icons.done_all : Icons.done,
                                size: 14,
                                color: isRead ? Colors.blue : Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _showStickers = !_showStickers), 
                    icon: Icon(_showStickers ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.blueAccent)
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      onTap: () => setState(() => _showStickers = false),
                      decoration: const InputDecoration(hintText: "Ketik pesan...", border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _sendMessage(text: _msgController.text),
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          ),
          if (_showStickers)
            SizedBox(
              height: 250,
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemCount: stickers.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => _sendMessage(stickerUrl: stickers[index]),
                  child: Image.network(stickers[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- ADMIN DASHBOARD ---
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUserStatus(true);
    } else if (state == AppLifecycleState.paused) {
      _setUserStatus(false);
    }
  }

  Future<void> _setUserStatus(bool status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'is_active': status,
        'last_seen': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _setUserStatus(false);
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        title: const Text("Admin KostKu", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where('receiverId', isEqualTo: user?.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int totalUnread = snapshot.data?.docs.length ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage())), 
                    icon: const Icon(Icons.chat_bubble_rounded)
                  ),
                  if (totalUnread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text("$totalUnread", style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    )
                ],
              );
            }
          ),
          IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox(height: 100);
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          backgroundImage: (data['foto_url'] != null && data['foto_url'].toString().isNotEmpty) 
                              ? NetworkImage(data['foto_url']) 
                              : const AssetImage('assets/images/logo.png') as ImageProvider,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['nama'] ?? "Admin", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text(user?.email ?? "-", style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _buildBarChartCard("Penghasilan (Rp)", [2, 4, 3, 6, 5, 8], "jt", Colors.green)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').where('nama_kost_aktif', isNotEqualTo: "").snapshots(),
                        builder: (context, snap) {
                          int terisi = snap.data?.docs.length ?? 0;
                          return _buildPieChartCard("Okupansi", terisi, Colors.orange);
                        }
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildActiveOrdersSection(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _menuCard(context, Icons.add_business, "Tambah Kost", Colors.blue, const TambahKostPage()),
                    _menuCard(context, Icons.home_work, "Daftar Kost", Colors.redAccent, const DaftarKostAktifPage()),
                    _menuCard(context, Icons.notification_important_rounded, "Konfirmasi Pesanan", Colors.orangeAccent, const AdminPesananPage()),
                    _menuCard(context, Icons.people, "Kelola User", Colors.orange, const KelolaUserPage()),
                    _menuCard(context, Icons.monetization_on, "Penghasilan", Colors.green, const PenghasilanPage()),
                    _menuCard(context, Icons.settings, "Settings", Colors.purple, const SettingSistemPage()),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartCard(String title, List<int> values, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(15), height: 180,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.map((v) => Container(width: 12, height: (v * 8).toDouble(), decoration: BoxDecoration(color: color.withOpacity(0.7), borderRadius: BorderRadius.circular(3)))).toList(),
          ),
          const SizedBox(height: 8),
          const Center(child: Text("Total Pendapatan", style: TextStyle(fontSize: 9, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(15), height: 180,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 60, height: 60, child: CircularProgressIndicator(value: count / 50, strokeWidth: 8, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color))),
                Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const Spacer(),
          Center(child: Text("$count Aktif", style: const TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('nama_kost_aktif', isNotEqualTo: "").limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("User Sedang Menghuni", style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ...snapshot.data!.docs.map((doc) {
                var d = doc.data() as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundImage: (d['foto_url'] != null) ? NetworkImage(d['foto_url']) : const AssetImage('assets/images/logo.png') as ImageProvider),
                  title: Text(d['nama'] ?? "User", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(d['nama_kost_aktif'] ?? "-", style: const TextStyle(fontSize: 11)),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _menuCard(BuildContext context, IconData icon, String title, Color color, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}