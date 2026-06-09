import 'dart:io';
import 'package:flutter/material.dart';

/// Widget for displaying images with proper aspect ratio
/// Images are never stretched - they maintain their aspect ratio
/// and are centered with black background
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
      _imageProvider = _getImageProvider();
    });
  }

  Future<ImageProvider> _getImageProvider() async {
    final file = File(widget.imagePath);
    if (await file.exists()) {
      return FileImage(file);
    }
    throw Exception('File not found: ${widget.imagePath}');
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
          widget.imagePath.split('/').last,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
