import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kai_slideshow/utils/constants.dart';

/// Info bar widget showing current image index and filename
/// Positioned at the bottom-left corner
class InfoBar extends StatelessWidget {
  final int currentIndex;
  final int totalImages;
  final String imagePath;

  const InfoBar({
    super.key,
    required this.currentIndex,
    required this.totalImages,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final filename = imagePath.split(Platform.pathSeparator).last;

    return Positioned(
      bottom: AppConstants.infoBarPadding,
      left: AppConstants.infoBarPadding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: AppConstants.infoBarColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(AppConstants.borderRadius),
            bottomRight: Radius.circular(AppConstants.borderRadius),
          ),
        ),
        child: Text(
          '$currentIndex / $totalImages   •   $filename',
          style: const TextStyle(color: AppConstants.secondaryTextColor),
        ),
      ),
    );
  }
}
