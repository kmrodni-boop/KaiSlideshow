import 'package:flutter/material.dart';

/// App constants
class AppConstants {
  static const String appName = 'Kai Slideshow';
  static const String noImagesMessage = 'No images selected';
  static const String noImagesSubtitle = 'Click "Add Files" or "Add Folder" to get started';
  static const String addFiles = 'Add Files';
  static const String addFolder = 'Add Folder';
  static const String exit = 'Exit';
  static const String intervalLabel = 'Interval:';
  static const String shuffleLabel = 'Shuffle';
  static const String pauseLabel = 'PAUSE';

  /// UI constants
  static const Duration uiHideDuration = Duration(seconds: 3);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 300);
  static const double controlBarHeight = 80;
  static const double infoBarPadding = 20;
  static const double borderRadius = 20;
  static const double buttonBorderRadius = 10;

  /// Color scheme
  static const Color backgroundColor = Colors.black;
  static const Color controlBarColor = Color.fromRGBO(35, 35, 35, 0.9);
  static const Color infoBarColor = Color.fromRGBO(20, 20, 20, 0.8);
  static const Color borderColor = Color(0xFF555555);
  static const Color textColor = Color(0xFFEEEEEE);
  static const Color secondaryTextColor = Color(0xFFDDDDDD);
  static const Color addButtonColor = Color(0xFF2980B9);
  static const Color exitButtonColor = Color(0xFFC0392B);

  /// Interval options (in seconds) - now includes longer options for elderly users
  static const List<int> intervalOptions = [2, 3, 5, 10, 20, 30, 60, 120];
}
