import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kai_slideshow/utils/file_utils.dart';

/// Handles command-line arguments and file/folder selection
class FileHandler {
  static const MethodChannel _channel = MethodChannel('kai_slideshow/intents');

  /// Process command-line arguments and return list of image paths
  static Future<List<String>> processArguments(List<String> arguments) async {
    final imagePaths = <String>[];

    for (final arg in arguments) {
      if (arg.isEmpty) continue;

      final file = File(arg);
      final dir = Directory(arg);

      if (await file.exists()) {
        // Single file
        if (isSupportedImage(arg)) {
          imagePaths.add(arg);
        }
      } else if (await dir.exists()) {
        // Directory - load all images recursively
        final images = await loadImagesFromDirectory(arg);
        imagePaths.addAll(images);
      }
    }

    return imagePaths;
  }

  /// Get initial URIs from Android intent (for Share functionality)
  static Future<List<String>> getInitialUris() async {
    try {
      if (Platform.isAndroid) {
        final List<dynamic>? uris = await _channel.invokeMethod('getInitialUris');
        if (uris != null) {
          return uris.map((uri) => uri.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting initial URIs: $e');
    }
    return [];
  }

  /// Convert Android content URIs to file paths
  /// This is a simplified version - in production, you'd need platform-specific code
  static Future<List<String>> convertUrisToPaths(List<String> uris) async {
    final paths = <String>[];
    
    for (final uri in uris) {
      // For file:// URIs, just use the path
      if (uri.startsWith('file://')) {
        final path = uri.substring(7); // Remove 'file://' prefix
        paths.add(path);
      } else if (Platform.isAndroid) {
        // For content:// URIs on Android, we need to use a platform channel
        // This is a placeholder - actual implementation requires native code
        try {
          // Try to get the path from the URI using a platform channel
          // This would require implementing a native method to resolve the URI
          paths.add(uri); // For now, just pass the URI
        } catch (e) {
          debugPrint('Could not convert URI to path: $uri');
        }
      }
    }
    
    return paths;
  }

  /// Process both command-line arguments and Android intents
  static Future<List<String>> processInitialFiles() async {
    // First, try to get URIs from Android intent
    final uris = await getInitialUris();
    if (uris.isNotEmpty) {
      return await convertUrisToPaths(uris);
    }
    
    // Fall back to command-line arguments
    // Note: On Android, command-line arguments are not typically available
    // This is mainly for desktop platforms
    return [];
  }

  /// Validate and filter a list of paths to only include valid images
  static Future<List<String>> filterValidImages(List<String> paths) async {
    final validImages = <String>[];

    for (final path in paths) {
      try {
        // Skip content:// URIs on Android for now
        if (path.startsWith('content://')) {
          validImages.add(path);
          continue;
        }
        
        final file = File(path);
        if (await file.exists() && isSupportedImage(path)) {
          validImages.add(path);
        }
      } catch (e) {
        // Skip invalid files
        continue;
      }
    }

    return validImages;
  }

  /// Get unique paths (remove duplicates)
  static List<String> getUniquePaths(List<String> paths) {
    return paths.toSet().toList();
  }
}
