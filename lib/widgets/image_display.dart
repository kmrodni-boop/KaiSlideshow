import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for displaying images with proper aspect ratio
/// Images are never stretched - they maintain their aspect ratio
/// and are centered with black background
/// Supports both file:// paths and content:// URIs (Android)
class ImageDisplay extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;

  const ImageDisplay({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
  });

  @override
  State<ImageDisplay> createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<ImageDisplay> {
  late Future<ImageProvider> _imageProvider;
  bool _errorLoading = false;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _loadImage();
    }
  }

  void _loadImage() {
    setState(() {
      _errorLoading = false;
      _imageBytes = null;
      _imageProvider = _getImageProvider();
    });
  }

  Future<ImageProvider> _getImageProvider() async {
    // Handle content:// URIs (Android Share intent)
    if (widget.imagePath.startsWith('content://') && Platform.isAndroid) {
      try {
        // Use platform channel to get file bytes from content URI
        final Uint8List? bytes = await _getBytesFromContentUri(widget.imagePath);
        if (bytes != null) {
          setState(() => _imageBytes = bytes);
          return MemoryImage(bytes);
        }
      } catch (e) {
        debugPrint('Error loading content URI: ${widget.imagePath} - $e');
      }
    }

    // Handle file:// URIs and regular file paths
    final file = File(widget.imagePath);
    if (await file.exists()) {
      return FileImage(file);
    }

    // Fallback for direct file paths
    try {
      final file = File(widget.imagePath);
      if (await file.exists()) {
        return FileImage(file);
      }
    } catch (e) {
      debugPrint('Error loading file: ${widget.imagePath} - $e');
    }

    throw Exception('File not found: ${widget.imagePath}');
  }

  Future<Uint8List?> _getBytesFromContentUri(String uri) async {
    try {
      final result = await MethodChannel('kai_slideshow/intents').invokeMethod(
        'getImageBytesFromUri',
        {'uri': uri},
      );
      
      if (result is Uint8List) {
        return result;
      } else if (result is List<int>) {
        return Uint8List.fromList(result);
      }
    } catch (e) {
      debugPrint('Error getting bytes from URI: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<ImageProvider>(
        future: _imageProvider,
        builder: (context, snapshot) {
          if (snapshot.hasError || _errorLoading) {
            return _buildErrorWidget();
          }
          if (!snapshot.hasData) {
            return _buildLoadingWidget();
          }
          
          // If we have bytes from content URI, use MemoryImage
          if (_imageBytes != null) {
            return Image.memory(
              _imageBytes!,
              fit: widget.fit,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                setState(() => _errorLoading = true);
                return _buildErrorWidget();
              },
            );
          }
          
          // Otherwise use the provider from FileImage
          return Image(
            image: snapshot.data!,
            fit: widget.fit,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              setState(() => _errorLoading = true);
              return _buildErrorWidget();
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const SizedBox(
      width: 64,
      height: 64,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final displayPath = widget.imagePath.split('/').last;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.white30),
        const SizedBox(height: 16),
        const Text(
          'Error loading image',
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 8),
        Text(
          displayPath,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
