import 'package:flutter/material.dart';
import 'memories_gallery_screen.dart';

/// Legacy screen alias forwarded to the enhanced MemoriesGalleryScreen
class PhotoGalleryScreen extends StatelessWidget {
  const PhotoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MemoriesGalleryScreen();
  }
}
