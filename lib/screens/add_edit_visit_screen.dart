import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/visit.dart';
import '../models/photo.dart';
import '../providers/restaurant_provider.dart';
import '../services/photo_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/date_formatter.dart';
import '../utils/haptic_service.dart';
import '../widgets/rating_bar.dart';
import '../widgets/safe_image.dart';

class AddEditVisitScreen extends StatefulWidget {
  final String restaurantId;
  final Visit? visit;

  const AddEditVisitScreen({
    super.key,
    required this.restaurantId,
    this.visit,
  });

  @override
  State<AddEditVisitScreen> createState() => _AddEditVisitScreenState();
}

class _AddEditVisitScreenState extends State<AddEditVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final PhotoStorageService _photoStorage = PhotoStorageService();

  late DateTime _visitDate;
  late TextEditingController _notesController;
  late TextEditingController _occasionController;
  double? _rating;

  List<Photo> _existingPhotos = [];
  final List<Photo> _newPhotosToSave = [];
  final List<String> _photosToDelete = [];

  bool _isSaving = false;
  bool _isPickingPhotos = false;

  @override
  void initState() {
    super.initState();
    final v = widget.visit;
    _visitDate = v?.visitDate ?? DateTime.now();
    _notesController = TextEditingController(text: v?.notes ?? '');
    _occasionController = TextEditingController(text: v?.occasion ?? '');
    _rating = v?.rating;

    if (v != null) {
      final provider = Provider.of<RestaurantProvider>(context, listen: false);
      _existingPhotos = List.from(provider.getPhotosForVisit(v.id));
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _occasionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    AppHaptics.selectionClick(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _visitDate = picked;
      });
    }
  }

  Future<void> _addPhotos() async {
    AppHaptics.selectionClick(context);
    setState(() => _isPickingPhotos = true);
    try {
      final result = await _photoStorage.pickPhotosFromGallery();
      if (!mounted) return;

      if (result.error != null && result.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!), backgroundColor: AppColors.error),
        );
      }

      if (result.savedPaths.isNotEmpty) {
        AppHaptics.lightImpact(context);
        setState(() {
          for (var path in result.savedPaths) {
            _newPhotosToSave.add(Photo(
              restaurantId: widget.restaurantId,
              visitId: widget.visit?.id,
              filePath: path,
            ));
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingPhotos = false);
    }
  }

  Future<void> _takePhoto() async {
    AppHaptics.selectionClick(context);
    setState(() => _isPickingPhotos = true);
    try {
      final result = await _photoStorage.takePhotoWithCamera();
      if (!mounted) return;

      if (result.error != null && result.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!), backgroundColor: AppColors.error),
        );
      }

      if (result.savedPaths.isNotEmpty) {
        AppHaptics.lightImpact(context);
        setState(() {
          _newPhotosToSave.add(Photo(
            restaurantId: widget.restaurantId,
            visitId: widget.visit?.id,
            filePath: result.savedPaths.first,
          ));
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingPhotos = false);
    }
  }

  void _removeExistingPhoto(Photo photo) {
    AppHaptics.selectionClick(context);
    setState(() {
      _existingPhotos.removeWhere((p) => p.id == photo.id);
      _photosToDelete.add(photo.id);
    });
  }

  void _removeNewPhoto(int index) {
    AppHaptics.selectionClick(context);
    setState(() {
      _newPhotosToSave.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<RestaurantProvider>(context, listen: false);

      final visitToSave = (widget.visit ?? Visit(restaurantId: widget.restaurantId)).copyWith(
        visitDate: _visitDate,
        isApproximateDate: false,
        mealType: widget.visit?.mealType,
        occasion: _occasionController.text.trim().isNotEmpty ? _occasionController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        rating: _rating,
      );

      final finalizedNewPhotos = _newPhotosToSave.map((p) => p.copyWith(visitId: visitToSave.id)).toList();

      await provider.saveVisit(
        visitToSave,
        photosToSave: finalizedNewPhotos,
        photosToDelete: _photosToDelete,
      );

      if (mounted) {
        AppHaptics.heavyImpact(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.visit == null ? 'Visit recorded!' : 'Visit updated!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save visit: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allCurrentPhotos = [..._existingPhotos, ..._newPhotosToSave];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.visit == null ? 'Record Visit' : 'Edit Visit',
          style: const TextStyle(fontFamily: 'Serif', fontSize: 18),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // 1. Visit Date Card (without approximate date checkbox)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Visit Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month_rounded, size: 18),
                            label: Text(DateFormatter.formatCompact(_visitDate)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Experience Rating Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Experience Rating:', style: TextStyle(fontWeight: FontWeight.w600)),
                          RatingBar(
                            rating: _rating ?? 0,
                            itemSize: 28,
                            isInteractive: true,
                            onRatingChanged: (r) {
                              AppHaptics.selectionClick(context);
                              setState(() => _rating = r);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Occasion (e.g. Date Night, Anniversary)
                  TextFormField(
                    controller: _occasionController,
                    decoration: InputDecoration(
                      labelText: 'Occasion (Optional)',
                      labelStyle: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      hintText: 'e.g. Date Night, Anniversary, Birthday, Weekend Getaway',
                      prefixIcon: const Icon(Icons.favorite_outline_rounded, size: 20, color: AppColors.softRose),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Visit Notes & Story (with dimmed, non-glaring hint text)
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Visit Notes & Memory Story',
                      labelStyle: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      hintText: 'What made this visit special? What did you order?',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.darkTextMuted.withValues(alpha: 0.6)
                            : AppColors.lightTextMuted.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Photos Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Photos (${allCurrentPhotos.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                      ),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            icon: _isPickingPhotos
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.photo_library_outlined),
                            onPressed: _isPickingPhotos ? null : _addPhotos,
                            tooltip: 'Pick from Gallery',
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.camera_alt_outlined),
                            onPressed: _isPickingPhotos ? null : _takePhoto,
                            tooltip: 'Take Photo',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (allCurrentPhotos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceSubtle,
                        borderRadius: AppDesignTokens.borderRadiusLarge,
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: const Center(
                        child: Text('No photos added for this visit yet.', style: TextStyle(color: AppColors.lightTextMuted)),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: allCurrentPhotos.length,
                      itemBuilder: (context, index) {
                        final isExisting = index < _existingPhotos.length;
                        final photo = isExisting ? _existingPhotos[index] : _newPhotosToSave[index - _existingPhotos.length];

                        return GestureDetector(
                          onLongPress: () {
                            AppHaptics.heavyImpact(context);
                            if (isExisting) {
                              _removeExistingPhoto(photo);
                            } else {
                              _removeNewPhoto(index - _existingPhotos.length);
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SafeImage(filePath: photo.filePath),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    if (isExisting) {
                                      _removeExistingPhoto(photo);
                                    } else {
                                      _removeNewPhoto(index - _existingPhotos.length);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // 5. Save Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.champagneGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
                    ),
                    onPressed: _save,
                    child: Text(
                      widget.visit == null ? 'Save Visit' : 'Update Visit',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
