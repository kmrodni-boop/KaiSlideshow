import 'dart:io';

/// Supported image file extensions
const List<String> supportedImageExtensions = [
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.bmp',
  '.gif',
];

/// Check if a file path has a supported image extension
bool isSupportedImage(String filePath) {
  final lowerPath = filePath.toLowerCase();
  return supportedImageExtensions.any(
    (ext) => lowerPath.endsWith(ext),
  );
}

/// Load image paths from a directory asynchronously
/// Returns a list of valid, existing image file paths
Future<List<String>> loadImagesFromDirectory(String directoryPath) async {
  final imagePaths = <String>[];

  try {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      return imagePaths;
    }

    await for (var entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          if (isSupportedImage(entity.path) && await entity.exists()) {
            imagePaths.add(entity.path);
          }
        } catch (e) {
          // Skip files that can't be accessed
          continue;
        }
      }
    }
  } catch (e) {
    // If directory can't be read, return empty list
    return [];
  }

  return imagePaths;
}
