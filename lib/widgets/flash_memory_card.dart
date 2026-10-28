import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_design_tokens.dart';
import 'glass_container.dart';
import 'safe_image.dart';

class FlashMemoryItem {
  final String photoPath;
  final String restaurantName;
  final String? subtitle;

  const FlashMemoryItem({
    required this.photoPath,
    required this.restaurantName,
    this.subtitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashMemoryItem &&
          runtimeType == other.runtimeType &&
          photoPath == other.photoPath &&
          restaurantName == other.restaurantName;

  @override
  int get hashCode => photoPath.hashCode ^ restaurantName.hashCode;
}

class FlashMemoryCard extends StatefulWidget {
  final List<FlashMemoryItem> items;

  const FlashMemoryCard({
    super.key,
    required this.items,
  });

  @override
  State<FlashMemoryCard> createState() => _FlashMemoryCardState();
}

class _FlashMemoryCardState extends State<FlashMemoryCard> {
  late List<FlashMemoryItem> _shuffledItems;
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _shuffledItems = List.from(widget.items)..shuffle();
    // Use an offset initial page to allow seamless swiping both left and right
    final initialPage = _shuffledItems.length > 1 ? 1000 * _shuffledItems.length : 0;
    _pageController = PageController(initialPage: initialPage);
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant FlashMemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      setState(() {
        _shuffledItems = List.from(widget.items)..shuffle();
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_shuffledItems.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shuffledItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      borderRadius: AppDesignTokens.borderRadiusLarge,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 235,
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            _resetTimer();
          },
          itemBuilder: (context, index) {
            final item = _shuffledItems[index % _shuffledItems.length];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Random Memory Photo
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox(
                      width: double.infinity,
                      child: SafeImage(
                        filePath: item.photoPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Restaurant Name below the photo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    item.restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Serif',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
