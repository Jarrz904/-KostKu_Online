import 'package:flutter/material.dart';

class QuickCategories extends StatelessWidget {
  // Callback function untuk mengirim label kategori ke Dashboard
  final Function(String)? onCategoryTap;
  // Parameter baru untuk melacak kategori mana yang aktif
  final String? selectedCategory;

  const QuickCategories({
    super.key, 
    this.onCategoryTap, 
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    // List kategori yang disesuaikan dengan logika filter di Dashboard
    final List<Map<String, dynamic>> categories = [
      {
        "icon": Icons.bolt_rounded, 
        "label": "Murah",
        "color": Colors.orange,
      },
      {
        "icon": Icons.star_rounded, 
        "label": "Eksklusif",
        "color": Colors.purple,
      },
      {
        "icon": Icons.female_rounded, 
        "label": "Putri",
        "color": Colors.pink,
      },
      {
        "icon": Icons.male_rounded, 
        "label": "Putra",
        "color": Colors.blue,
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.map((cat) {
          // Cek apakah kategori ini sedang dipilih
          final bool isSelected = selectedCategory == cat['label'];
          final Color themeColor = cat['color'] as Color;

          return InkWell(
            // Efek tap yang rapi mengikuti bentuk kontainer
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              if (onCategoryTap != null) {
                onCategoryTap!(cat['label']);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Container Ikon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // Jika dipilih, warna background lebih pekat
                      color: isSelected 
                          ? themeColor.withOpacity(0.2) 
                          : themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      // Tambahkan border tipis jika terpilih
                      border: Border.all(
                        color: isSelected ? themeColor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      cat['icon'], 
                      color: themeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Label Teks
                  Text(
                    cat['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? themeColor : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Indikator Garis Bawah
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    width: isSelected ? 20 : 0, // Garis memanjang jika terpilih
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}