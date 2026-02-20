# 🏠 KostKu Online - Sistem Manajemen Kost Modern

**KostKu Online** adalah platform terintegrasi yang dirancang untuk mempermudah pengelolaan kost bagi pemilik (Admin) dan pencarian unit bagi penyewa (User). Aplikasi ini dibangun menggunakan **Flutter** untuk sisi mobile dan **Next.js** untuk dashboard monitoring, dengan dukungan penuh dari **Firebase** sebagai backend utama.

---

## 🚀 Deskripsi Aplikasi

Aplikasi ini bertujuan untuk mendigitalkan proses persewaan kost yang konvensional. Melalui KostKu Online, pemilik kost dapat memantau pendapatan, mengelola unit, dan berkomunikasi dengan penyewa secara real-time melalui sistem notifikasi otomatis.

### Fitur Utama:
* **User Dashboard**: Antarmuka bagi pencari kost untuk melihat katalog unit yang tersedia secara real-time.
* **Admin Monitoring**: Dashboard khusus untuk memantau pesanan masuk, penghasilan bulanan, dan kelola database user.
* **Smart Notifications (API V1)**: Notifikasi mengambang (Heads-up) untuk informasi mendesak seperti pengumuman kost atau status pembayaran.
* **Integrasi Cloudinary**: Penyimpanan gambar unit kost yang efisien dan cepat.
* **Multi-Platform Support**: Tersedia untuk Android, iOS, dan Web (Monitoring).

---

## 🛠️ Arsitektur Teknologi

* **Frontend Mobile**: Flutter (Dart)
* **Frontend Web/Admin**: Next.js / Node.js
* **Database & Auth**: Firebase Firestore & Firebase Auth
* **Push Notifications**: Firebase Cloud Messaging (FCM) API V1
* **Storage**: Cloudinary API

---

## 📦 Struktur Folder Proyek

```text
aplikasi_kost/
├── android/              # Konfigurasi platform Android
├── ios/                  # Konfigurasi platform iOS
├── lib/                  # Logika aplikasi Flutter
│   ├── widgets/          # Komponen UI reusable
│   ├── main.dart         # Entry point aplikasi
│   └── firebase_options.dart # Konfigurasi Firebase
├── dashboard-monitoring/ # Web dashboard menggunakan Next.js
└── pubspec.yaml          # Dependensi Flutter
⚙️ Cara Menjalankan Proyek
1. Prasyarat
Flutter SDK terpasang.

Node.js terpasang (untuk Dashboard).

Akun Firebase dengan API Cloud Messaging (V1) aktif.

2. Setup Firebase
Unduh google-services.json dan letakkan di android/app/.

Pastikan Cloud Messaging API (V1) dalam status Enabled di Console Firebase.

3. Setup Admin SDK (Penting)
Untuk dashboard monitoring, Anda memerlukan file kunci privat JSON dari Firebase Service Account.

Dapatkan file di: Project Settings > Service Accounts.

Simpan di folder dashboard-monitoring/ dengan nama yang aman.

Catatan Keamanan: Jangan pernah mem-push file ini ke GitHub (Sudah terdaftar di .gitignore).

4. Menjalankan Aplikasi
Bash
# Menjalankan Flutter
flutter pub get
flutter run

# Menjalankan Dashboard
cd dashboard-monitoring
npm install
npm run dev
🔒 Keamanan Data
Proyek ini menggunakan standar keamanan OAuth 2.0 melalui Firebase Admin SDK untuk pengiriman notifikasi, memastikan kredensial server Anda tetap aman dan terenkripsi.

Developed with ❤️ for KostKu Online.


---

### Langkah Terakhir:
1.  Buat file baru di VS Code dengan nama `README.md`.
2.  Tempelkan kode di atas ke dalamnya.
3.  Simpan, lalu lakukan `git add README.md`, `git commit -m "Add README description"`, dan `git push`.

Apakah README ini sudah cukup menggambarkan visi aplikasi Anda, atau ada fitur tambahan yang ingin Anda masukkan ke dalam deskripsi?