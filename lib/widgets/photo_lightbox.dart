import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/photo.dart';
import '../providers/restaurant_provider.dart';
import '../screens/restaurant_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/date_formatter.dart';
import '../utils/haptic_service.dart';
import '../utils/shuffle_helper.dart';
import 'our_story_memory_sheet.dart';
import 'safe_image.dart';
import 'scrapbook_card.dart';

class PhotoLightbox extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;
  final bool isSlideshowActive;
  final bool isShuffleMode;
  final int slideshowIntervalSeconds;

  const PhotoLightbox({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.isSlideshowActive = false,
    this.isShuffleMode = false,
    this.slideshowIntervalSeconds = 5,
  });

  @override
  State<PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<PhotoLightbox> with WidgetsBindingObserver {
  late PageController _pageController;
  late int _currentIndex;
  late List<Photo> _photosList;
  late bool _isPlayingSlideshow;
  late bool _isShuffle;
  late int _intervalSeconds;
  Timer? _slideshowTimer;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isShuffle = widget.isShuffleMode;
    _intervalSeconds = widget.slideshowIntervalSeconds;
    _isPlayingSlideshow = widget.isSlideshowActive;

    if (_isShuffle && widget.photos.length > 1) {
      _photosList = ShuffleHelper.createDiverseShuffleSequence(widget.photos);
      _currentIndex = 0;
    } else {
      _photosList = List.from(widget.photos);
      _currentIndex = widget.initialIndex.clamp(0, _photosList.isEmpty ? 0 : _photosList.length - 1);
    }

    _pageController = PageController(initialPage: _currentIndex);

    if (_isPlayingSlideshow) {
      _startSlideshowTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseSlideshow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _slideshowTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startSlideshowTimer() {
    _slideshowTimer?.cancel();
    if (_photosList.length <= 1) return;

    _slideshowTimer = Timer.periodic(Duration(seconds: _intervalSeconds), (_) {
      if (!mounted || !_pageController.hasClients) return;

      if (_currentIndex < _photosList.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      } else {
        if (_isShuffle) {
          setState(() {
            _photosList = ShuffleHelper.createDiverseShuffleSequence(widget.photos);
          });
          _pageController.jumpToPage(0);
        } else {
          _pageController.jumpToPage(0);
        }
      }
    });
  }

  void _pauseSlideshow() {
    if (_isPlayingSlideshow) {
      setState(() {
        _isPlayingSlideshow = false;
      });
      _slideshowTimer?.cancel();
    }
  }

  void _toggleSlideshow() {
    AppHaptics.selectionClick(context);
    setState(() {
      _isPlayingSlideshow = !_isPlayingSlideshow;
    });

    if (_isPlayingSlideshow) {
      _startSlideshowTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          content: Text('Slideshow started (${_intervalSeconds}s per memory)'),
        ),
      );
    } else {
      _slideshowTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1200),
          content: Text('Slideshow paused'),
        ),
      );
    }
  }

  void _toggleShuffle() {
    AppHaptics.selectionClick(context);
    setState(() {
      _isShuffle = !_isShuffle;
      if (_isShuffle) {
        _photosList = ShuffleHelper.createDiverseShuffleSequence(widget.photos);
        _currentIndex = 0;
        _pageController.jumpToPage(0);
      } else {
        _photosList = List.from(widget.photos);
        _currentIndex = 0;
        _pageController.jumpToPage(0);
      }
    });

    if (_isPlayingSlideshow) {
      _startSlideshowTimer();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        content: Text(
          _isShuffle
              ? 'Shuffle Memories Active (no repeats within sequence)'
              : 'Sequential Order Restored',
        ),
      ),
    );
  }

  void _onUserInteractedPage(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (_isPlayingSlideshow) {
      _startSlideshowTimer();
    }
  }

  void _openVisitDetails(BuildContext context, Photo photo, RestaurantProvider provider) {
    _pauseSlideshow();
    final visit = provider.getVisitById(photo.visitId);
    final restaurant = provider.getRestaurantById(photo.restaurantId);

    if (visit != null) {
      final allVisits = provider.allVisits;
      final seq = allVisits.where((v) => v.restaurantId == visit.restaurantId).toList();
      seq.sort((a, b) {
        if (a.visitDate == null && b.visitDate == null) return a.createdAt.compareTo(b.createdAt);
        if (a.visitDate == null) return 1;
        if (a.visitDate == null) return -1;
        return a.visitDate!.compareTo(b.visitDate!);
      });
      final idx = seq.indexWhere((v) => v.id == visit.id);
      final seqNum = idx >= 0 ? idx + 1 : 1;
      final total = provider.getVisitCountForRestaurant(visit.restaurantId);

      OurStoryMemorySheet.show(
        context,
        visit: visit,
        restaurant: restaurant,
        visitSequence: seqNum,
        totalVisits: total,
      );
    } else if (restaurant != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(restaurantId: restaurant.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_photosList.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: const Center(child: Text('No photos in collection', style: TextStyle(color: Colors.white))),
      );
    }

    final provider = Provider.of<RestaurantProvider>(context);
    final currentPhoto = _photosList[_currentIndex];
    final restaurant = provider.getRestaurantById(currentPhoto.restaurantId);
    final visit = provider.getVisitById(currentPhoto.visitId);

    // Derived metadata
    final restaurantName = restaurant?.name ?? 'Restaurant Memory';
    final visitDateStr = visit?.visitDate != null
        ? DateFormatter.formatFull(visit!.visitDate, isApproximate: visit.isApproximateDate)
        : DateFormatter.formatShort(currentPhoto.createdAt);
    final occasionEmoji = ScrapbookCard.getOccasionEmoji(visit?.occasion);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isShuffle
                        ? 'Shuffle • ${_currentIndex + 1} of ${_photosList.length}'
                        : '${_currentIndex + 1} of ${_photosList.length}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (_isPlayingSlideshow)
                    const Text(
                      'Slideshow Playing',
                      style: TextStyle(fontSize: 11, color: AppColors.champagneGold),
                    ),
                ],
              ),
              actions: [
                // Play / Pause Slideshow button
                IconButton(
                  icon: Icon(
                    _isPlayingSlideshow ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: _isPlayingSlideshow ? AppColors.champagneGold : Colors.white,
                    size: 26,
                  ),
                  tooltip: _isPlayingSlideshow ? 'Pause Slideshow' : 'Play Slideshow',
                  onPressed: _toggleSlideshow,
                ),

                // Shuffle button
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: _isShuffle ? AppColors.champagneGold : Colors.white70,
                  ),
                  tooltip: _isShuffle ? 'Shuffle Active (No repeats)' : 'Shuffle Memories',
                  onPressed: _toggleShuffle,
                ),

                // Speed sliding bar
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_intervalSeconds}s',
                        style: const TextStyle(
                          color: AppColors.champagneGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: SliderTheme(
                          data: const SliderThemeData(
                            trackHeight: 2,
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: AppColors.champagneGold,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: AppColors.champagneGold,
                          ),
                          child: Slider(
                            value: _intervalSeconds.toDouble().clamp(1.0, 10.0),
                            min: 1.0,
                            max: 10.0,
                            divisions: 9,
                            onChanged: (val) {
                              AppHaptics.selectionClick(context);
                              setState(() {
                                _intervalSeconds = val.round();
                              });
                              if (_isPlayingSlideshow) {
                                _startSlideshowTimer();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // PageView for swipeable photos
            PageView.builder(
              controller: _pageController,
              itemCount: _photosList.length,
              onPageChanged: _onUserInteractedPage,
              itemBuilder: (context, index) {
                final photo = _photosList[index];
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: SafeImage(
                      filePath: photo.filePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),

            // Left / Right touch navigation arrows when controls are shown
            if (_showControls && _photosList.length > 1) ...[
              if (_currentIndex > 0)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black38,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              if (_currentIndex < _photosList.length - 1)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black38,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
            ],

            // Bottom Information Overlay (Restaurant, Visit Date, Occasion, Actions)
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.black54,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    MediaQuery.of(context).padding.bottom > 0
                        ? MediaQuery.of(context).padding.bottom + 12
                        : 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant name & occasion
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurantName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Serif',
                              ),
                            ),
                          ),
                          if (visit?.occasion != null && visit!.occasion!.trim().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.champagneGold.withAlpha(200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (occasionEmoji != null) ...[
                                    Text(occasionEmoji, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    visit.occasion!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (visitDateStr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          visitDateStr,
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],

                      if (currentPhoto.caption != null && currentPhoto.caption!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          currentPhoto.caption!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Action Buttons: View Visit Memory & View Restaurant
                      Row(
                        children: [
                          if (currentPhoto.visitId != null && visit != null) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.champagneGold,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusMedium),
                                ),
                                icon: const Icon(Icons.auto_stories_rounded, size: 17),
                                label: const Text('View Visit Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                onPressed: () => _openVisitDetails(context, currentPhoto, provider),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusMedium),
                              ),
                              icon: const Icon(Icons.restaurant_rounded, size: 17),
                              label: const Text('Restaurant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                _pauseSlideshow();
                                if (restaurant != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailScreen(restaurantId: restaurant.id),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
