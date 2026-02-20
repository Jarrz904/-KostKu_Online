import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  // Menggunakan data yang Anda berikan
  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'di6fieqgs', 
    'u8v2nx1z', 
    cache: false
  );

  Future<String?> uploadImage(String filePath) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Image,
          folder: 'foto_kost', // Folder otomatis di Cloudinary Anda
        ),
      );
      return response.secureUrl; // URL inilah yang akan disimpan ke Firestore
    } catch (e) {
      print("Error Cloudinary: $e");
      return null;
    }
  }
}