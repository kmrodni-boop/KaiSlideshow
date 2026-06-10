import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
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
        if (uris != null && uris.isNotEmpty) {
          return uris.map((uri) => uri.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting initial URIs: $e');
    }
    return [];
  }

  /// Convert Android content URIs to file paths
  /// This handles both file:// and content:// URIs
  static Future<List<String>> convertUrisToPaths(List<String> uris) async {
    final paths = <String>[];
    
    for (final uri in uris) {
      if (uri.isEmpty) continue;
      
      // Handle file:// URIs
      if (uri.startsWith('file://')) {
        final path = uri.substring(7); // Remove 'file://' prefix
        if (isSupportedImage(path)) {
          paths.add(path);
        }
        continue;
      }
      
      // Handle content:// URIs (Android Share intent)
      if (uri.startsWith('content://') && Platform.isAndroid) {
        try {
          // Use platform channel to resolve content URI to file path
          final String? filePath = await _channel.invokeMethod(
            'getFilePathFromUri',
            {'uri': uri},
          );
          
          if (filePath != null && filePath.isNotEmpty && isSupportedImage(filePath)) {
            paths.add(filePath);
          }
        } catch (e) {
          debugPrint('Error resolving content URI: $uri - $e');
          // Fallback: try to use the URI directly (some plugins handle it)
          paths.add(uri);
        }
      }
      
      // Handle regular file paths
      if (isSupportedImage(uri)) {
        paths.add(uri);
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
    return [];
  }

  /// Validate and filter a list of paths to only include valid images
  static Future<List<String>> filterValidImages(List<String> paths) async {
    final validImages = <String>[];

    for (final path in paths) {
      try {
        // Skip empty paths
        if (path.isEmpty) continue;
        
        // For content:// URIs on Android, we can't check existence directly
        if (path.startsWith('content://') && Platform.isAndroid) {
          validImages.add(path);
          continue;
        }
        
        final file = File(path);
        if (await file.exists() && isSupportedImage(path)) {
          validImages.add(path);
        }
      } catch (e) {
        debugPrint('Error validating path: $path - $e');
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
