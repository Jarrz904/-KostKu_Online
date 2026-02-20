import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

class KelolaUserPage extends StatelessWidget {
  const KelolaUserPage({super.key});

  // Fungsi untuk format timestamp ke Jam:Menit
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return DateFormat('HH:mm').format(date);
  }

  // Fungsi untuk Menghapus User (Firestore + Authentication)
  Future<void> _deleteUser(BuildContext context, String docId, String email, String password) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus User"),
        content: Text("Yakin ingin menghapus $email? Akun login dan data database akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // 1. Inisialisasi Aplikasi Sementara untuk menghapus Auth tanpa mengganggu login Admin
                FirebaseApp tempApp = await Firebase.initializeApp(
                  name: 'TempAppDelete',
                  options: Firebase.app().options,
                );

                // 2. Login sebagai user yang akan dihapus
                UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
                    .signInWithEmailAndPassword(email: email, password: password);

                // 3. Hapus dari Authentication
                await userCredential.user!.delete();
                await tempApp.delete();

                // 4. Hapus dari Firestore
                await FirebaseFirestore.instance.collection('users').doc(docId).delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User berhasil dihapus sepenuhnya")));
                }
              } catch (e) {
                debugPrint("Error Delete: $e");
                // Jika gagal hapus auth (misal password salah), tetap hapus firestore atau beri peringatan
                await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk Tambah User (Sekarang Sinkron dengan Authentication)
  Future<void> _addUser(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    String selectedRole = 'user';
    bool obscureText = true;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Tambah User Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nama Lengkap", icon: Icon(Icons.person)),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email", icon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "WhatsApp", icon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: passwordController,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    labelText: "Kata Sandi",
                    icon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureText = !obscureText),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedRole,
                  isExpanded: true,
                  items: ['user', 'admin'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text("Role: $value"),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() => selectedRole = newValue!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) return;

                try {
                  // 1. Buat Akun di Firebase Authentication tanpa me-logout Admin
                  FirebaseApp tempApp = await Firebase.initializeApp(
                    name: 'TempAppCreate',
                    options: Firebase.app().options,
                  );

                  UserCredential res = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                  );

                  String newUid = res.user!.uid;

                  // 2. Simpan ke Firestore menggunakan UID yang baru saja dibuat
                  await FirebaseFirestore.instance.collection('users').doc(newUid).set({
                    'created_at': FieldValue.serverTimestamp(),
                    'email': emailController.text.trim(),
                    'is_online': false, // Default false, akan jadi true saat user tersebut login pertama kali
                    'last_online': FieldValue.serverTimestamp(),
                    'nama': nameController.text.trim(),
                    'role': selectedRole,
                    'uid': newUid,
                    'whatsapp': phoneController.text.trim(),
                    'password': passwordController.text, // Disimpan agar admin bisa menghapus akun nanti
                    'foto_url': '',
                  });

                  await tempApp.delete(); // Hapus koneksi aplikasi sementara

                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  debugPrint("Error adding user: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${e.toString()}")));
                  }
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk Edit User
  Future<void> _editUser(BuildContext context, String docId, Map<String, dynamic> data) async {
    TextEditingController nameController = TextEditingController(text: data['nama']);
    TextEditingController phoneController = TextEditingController(text: data['whatsapp'] ?? "");
    String selectedRole = data['role'] ?? 'user';

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit User"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nama Lengkap"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "WhatsApp"),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedRole,
                  isExpanded: true,
                  items: ['user', 'admin'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text("Role: $value"),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() => selectedRole = newValue!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(docId).update({
                  'nama': nameController.text.trim(),
                  'whatsapp': phoneController.text.trim(),
                  'role': selectedRole,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajemen User"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Terjadi kesalahan"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              bool isOnline = data['is_online'] ?? false;
              String lastSeen = _formatTimestamp(data['last_online'] as Timestamp?);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: data['foto_url'] != null && data['foto_url'] != ""
                            ? NetworkImage(data['foto_url'])
                            : null,
                        child: data['foto_url'] == null || data['foto_url'] == ""
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['nama'] ?? "User",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? "• Online" : "• Offline $lastSeen",
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['email'] ?? ""),
                      Text(data['whatsapp'] ?? "No WA", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      const SizedBox(height: 5),
                      Chip(
                        label: Text(
                          data['role'] ?? "user",
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        backgroundColor: data['role'] == 'admin' ? Colors.redAccent : Colors.orange,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUser(context, docId, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(
                          context,
                          docId,
                          data['email'] ?? "",
                          data['password'] ?? "",
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _addUser(context),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}