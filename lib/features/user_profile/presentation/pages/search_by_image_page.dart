// ignore_for_file: always_put_control_body_on_new_line
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/cards/product_card.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../injection_container.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../data/datasources/search_by_image_remote_data_source.dart';
import '../../../../core/icons/app_icon.dart';

class SearchByImagePage extends StatefulWidget {
  const SearchByImagePage({super.key});

  @override
  State<SearchByImagePage> createState() => _SearchByImagePageState();
}

class _SearchByImagePageState extends State<SearchByImagePage> {
  File? _selectedImage;
  List<ProductEntity> _results = const <ProductEntity>[];
  bool _isSearching = false;
  String? _apiMessage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile == null) return;
      setState(() {
        _selectedImage = File(pickedFile.path);
        _results = const <ProductEntity>[];
        _apiMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      showSnackBar(context, 'error', 'image_pick_failed', Colors.red);
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppPalette.of(context).surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const AppIcon(
                  IconlyLight.camera,
                  color: ColorConstants.primaryColor,
                ),
                title: Text('camera'.tr),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const AppIcon(
                  IconlyLight.image,
                  color: ColorConstants.primaryColor,
                ),
                title: Text('gallery'.tr),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performSearch() async {
    if (_selectedImage == null) return;
    setState(() {
      _isSearching = true;
      _apiMessage = null;
      _results = const <ProductEntity>[];
    });

    final result = await sl<SearchByImageRemoteDataSource>().searchByImage(
      _selectedImage!,
    );

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      if (result is Success<List<ProductEntity>>) {
        _results = result.dataOrThrow;
      } else if (result is Failure<List<ProductEntity>>) {
        _apiMessage = result.failureOrThrow.message;
      }
    });
    if (result is Failure<List<ProductEntity>> &&
        (_apiMessage == null || _apiMessage!.isEmpty)) {
      showSnackBar(context, 'error', 'search_failed', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBarForeground =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: AppIcon(IconlyLight.arrowLeftCircle, color: appBarForeground),
        ),
        title: Text(
          'search_by_image'.tr,
          style: TextStyle(
            color: appBarForeground,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildPremiumPicker(),
            if (_selectedImage != null) _buildSearchButton(),
            if (_isSearching) _buildLoadingState(),
            if (!_isSearching && _apiMessage != null && _results.isEmpty)
              _buildNoResultsState(),
            if (!_isSearching && _results.isNotEmpty) _buildResultsGrid(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumPicker() {
    return GestureDetector(
      onTap: _showPickerOptions,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppPalette.of(context).surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: ColorConstants.primaryColor.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon(
                      IconlyLight.image,
                      size: 48,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'tap_to_pick_image'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.of(context).text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'find_collars_desc'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.of(context).muted,
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.of(context).surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const AppIcon(
                            IconlyLight.edit,
                            size: 18,
                            color: ColorConstants.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'change'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: ColorConstants.primaryColor,
                            ),
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

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSearching ? null : _performSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryColor,
            minimumSize: const Size(double.infinity, 64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Text(
            'search'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(
          color: ColorConstants.primaryColor,
          strokeWidth: 3,
        ),
        const SizedBox(height: 20),
        Text(
          'searching'.tr,
          style: TextStyle(
            color: AppPalette.of(context).muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const AppIcon(IconlyLight.moreCircle, size: 80, color: Colors.orange),
          const SizedBox(height: 20),
          Text(
            _apiMessage ?? 'no_results_found'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPalette.of(context).text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'search_results'.tr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.of(context).text,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'count_results'.tr.replaceAll('@count', '${_results.length}'),
                  style: const TextStyle(
                    color: ColorConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
          ),
          itemCount: _results.length,
          itemBuilder: (context, index) {
            return ProductCard(product: _results[index]);
          },
        ),
      ],
    );
  }
}
