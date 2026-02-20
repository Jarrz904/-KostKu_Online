import 'package:flutter/material.dart';

class HeroCarousel extends StatelessWidget {
  final PageController controller;
  final List<Map<String, String>> images;
  final int activePage;
  final Function(int) onPageChanged;

  const HeroCarousel({
    super.key, 
    required this.controller, 
    required this.images, 
    required this.activePage,
    required this.onPageChanged
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(images[index]['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(images[index]['title']!, 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(images[index]['sub']!, 
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 25,
            right: 40,
            child: Row(
              children: List.generate(
                images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 5),
                  height: 6,
                  width: activePage == index ? 20 : 6,
                  decoration: BoxDecoration(
                    color: activePage == index ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}