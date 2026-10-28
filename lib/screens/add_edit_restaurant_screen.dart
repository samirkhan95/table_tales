import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../services/photo_storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../utils/haptic_service.dart';
import '../widgets/safe_image.dart';

class AddEditRestaurantScreen extends StatefulWidget {
  final Restaurant? restaurant;

  const AddEditRestaurantScreen({super.key, this.restaurant});

  @override
  State<AddEditRestaurantScreen> createState() => _AddEditRestaurantScreenState();
}

class _AddEditRestaurantScreenState extends State<AddEditRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final PhotoStorageService _photoStorage = PhotoStorageService();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  bool _isFavorite = false;
  String? _coverPhotoPath;
  bool _isSaving = false;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    final r = widget.restaurant;
    _nameController = TextEditingController(text: r?.name ?? '');
    _locationController = TextEditingController(text: r?.location ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');

    _isFavorite = r?.isFavorite ?? false;
    _coverPhotoPath = r?.coverPhotoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverPhoto() async {
    AppHaptics.selectionClick(context);
    setState(() => _isPickingPhoto = true);
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
          _coverPhotoPath = result.savedPaths.first;
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<RestaurantProvider>(context, listen: false);

    // Duplicate prevention check when adding new restaurant
    if (widget.restaurant == null) {
      final duplicate = await provider.checkDuplicateRestaurant(
        _nameController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (duplicate != null && mounted) {
        AppHaptics.selectionClick(context);
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusLarge),
            title: const Text('Similar Restaurant Found'),
            content: Text(
              'A restaurant named "${duplicate.name}" already exists in your collection. Do you want to save this anyway as a separate restaurant?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.champagneGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusPill),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save Anyway'),
              ),
            ],
          ),
        );

        if (proceed != true) return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = (widget.restaurant ?? Restaurant(name: _nameController.text.trim())).copyWith(
        name: _nameController.text.trim(),
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        coverPhotoPath: _coverPhotoPath,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        isFavorite: _isFavorite,
      );

      await provider.saveRestaurant(updated);

      if (mounted) {
        AppHaptics.heavyImpact(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.restaurant == null ? 'Restaurant added!' : 'Restaurant updated!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save restaurant: $e'), backgroundColor: AppColors.error),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.restaurant == null ? 'Add Restaurant' : 'Edit Restaurant',
          style: const TextStyle(fontFamily: 'Serif'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: _isFavorite ? AppColors.favoriteGold : null,
            ),
            onPressed: () {
              AppHaptics.mediumImpact(context);
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Cover photo section
                  GestureDetector(
                    onTap: _isPickingPhoto ? null : _pickCoverPhoto,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceSubtle,
                        borderRadius: AppDesignTokens.borderRadiusLarge,
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: _isPickingPhoto
                          ? const Center(child: CircularProgressIndicator())
                          : _coverPhotoPath != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: AppDesignTokens.borderRadiusLarge,
                                      child: SizedBox.expand(
                                        child: SafeImage(filePath: _coverPhotoPath),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                          onPressed: _pickCoverPhoto,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.champagneGold),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Cover Photo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name (Required)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Restaurant Name *',
                      prefixIcon: Icon(Icons.restaurant_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter restaurant name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location / Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description / Notes
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Overall Description & Notes',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Save Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.champagneGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: AppDesignTokens.borderRadiusMedium),
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: Text(
                      widget.restaurant == null ? 'Save Restaurant' : 'Update Restaurant',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
