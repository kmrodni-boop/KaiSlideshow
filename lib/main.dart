import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kai_slideshow/models/slideshow_settings.dart';
import 'package:kai_slideshow/utils/constants.dart';
import 'package:kai_slideshow/utils/file_utils.dart';
import 'package:kai_slideshow/utils/file_handler.dart';
import 'package:kai_slideshow/widgets/image_display.dart';
import 'package:kai_slideshow/widgets/info_bar.dart';
import 'package:kai_slideshow/widgets/control_bar.dart';

// Global variable to store initial file arguments
List<String> initialFileArguments = [];

void main(List<String> arguments) async {
  // Store arguments for later use
  initialFileArguments = arguments;
  
  // Initialize Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Process arguments and Android intents
  final imagePaths = await _processInitialFiles();
  
  // If we have image paths, start directly with slideshow
  if (imagePaths.isNotEmpty) {
    runApp(KaiSlideshowApp(initialImages: imagePaths));
  } else {
    runApp(const KaiSlideshowApp());
  }
}

/// Process initial files from command-line arguments or Android intents
Future<List<String>> _processInitialFiles() async {
  // Try to get files from Android intent first
  final intentFiles = await FileHandler.processInitialFiles();
  if (intentFiles.isNotEmpty) {
    return intentFiles;
  }
  
  // Fall back to command-line arguments (for desktop)
  return await FileHandler.processArguments(initialFileArguments);
}

class KaiSlideshowApp extends StatelessWidget {
  final List<String>? initialImages;

  const KaiSlideshowApp({super.key, this.initialImages});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppConstants.backgroundColor,
      ),
      home: SlideshowScreen(initialImages: initialImages),
    );
  }
}

class SlideshowScreen extends StatefulWidget {
  final List<String>? initialImages;

  const SlideshowScreen({super.key, this.initialImages});

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  // State
  final List<String> _imageList = [];
  int _currentIndex = 0;
  SlideshowSettings _settings = SlideshowSettings.defaultSettings;
  bool _isPlaying = false;
  bool _showUI = true;
  bool _isLoading = false;
  bool _isFullscreen = false;
  bool _initialLoadComplete = false;

  // Timers
  Timer? _slideTimer;
  Timer? _uiTimer;

  // Focus for keyboard input
  final FocusNode _focusNode = FocusNode();

  // Preferences
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _uiTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    // Load preferences
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();

    // Process initial images if provided
    if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
      final validImages = await FileHandler.filterValidImages(widget.initialImages!);
      if (validImages.isNotEmpty) {
        setState(() {
          _imageList.addAll(FileHandler.getUniquePaths(validImages));
          _applySorting();
        });
      }
    }

    // Request focus for keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Auto-start slideshow if we have images from command line or intent
      if (_imageList.isNotEmpty && !_initialLoadComplete) {
        _initialLoadComplete = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _togglePlay();
        });
      }
    });

    // Start UI hide timer
    _startUiTimer();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsMap = {
        'interval': _prefs.getInt('interval') ?? 5,
        'shuffle': _prefs.getBool('shuffle') ?? true,
      };
      setState(() {
        _settings = SlideshowSettings.fromJson(settingsMap);
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    await _prefs.setInt('interval', _settings.interval);
    await _prefs.setBool('shuffle', _settings.shuffle);
  }

  // --- Image Loading ---

  Future<void> _pickFolder() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath != null) {
        final newImages = await loadImagesFromDirectory(directoryPath);

        if (newImages.isNotEmpty) {
          setState(() {
            _imageList.addAll(FileHandler.getUniquePaths(newImages));
            _applySorting();
            if (!_isPlaying && _imageList.isNotEmpty) {
              _togglePlay();
            }
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No images found in the selected folder. Make sure the folder contains supported image files (jpg, png, webp, etc.)'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking folder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing folder: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFiles() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final newImagePaths = <String>[];
        for (var file in result.files) {
          if (file.path != null && isSupportedImage(file.path!)) {
            newImagePaths.add(file.path!);
          }
        }

        if (newImagePaths.isNotEmpty) {
          setState(() {
            _imageList.addAll(FileHandler.getUniquePaths(newImagePaths));
            _applySorting();
            if (!_isPlaying && _imageList.isNotEmpty) {
              _togglePlay();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySorting() {
    setState(() {
      if (_settings.shuffle) {
        _imageList.shuffle(Random());
      } else {
        _imageList.sort();
      }
      _currentIndex = 0;
    });
  }

  // --- Navigation ---

  void _showNext() {
    if (_imageList.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _imageList.length;
    });
  }

  void _showPrevious() {
    if (_imageList.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1) % _imageList.length;
      if (_currentIndex < 0) _currentIndex = _imageList.length - 1;
    });
  }

  // --- Playback Control ---

  void _togglePlay() {
    setState(() {
      if (_isPlaying) {
        _slideTimer?.cancel();
        _isPlaying = false;
        _showUI = true;
        _uiTimer?.cancel();
      } else {
        _isPlaying = true;
        _showUI = false;
        _startSlideTimer();
        _startUiTimer();
      }
    });
  }

  void _startSlideTimer() {
    _slideTimer?.cancel();
    if (_imageList.isNotEmpty) {
      _slideTimer = Timer.periodic(
        Duration(seconds: _settings.interval),
        (timer) {
          if (mounted) {
            _showNext();
          }
        },
      );
    }
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    if (!_isPlaying) return;

    _uiTimer = Timer(AppConstants.uiHideDuration, () {
      if (mounted && _isPlaying) {
        setState(() => _showUI = false);
      }
    });
  }

  void _onInteraction() {
    if (!_showUI) {
      setState(() => _showUI = true);
    }
    if (_isPlaying) {
      _startUiTimer();
    }
  }

  // --- Fullscreen Control ---

  Future<void> _toggleFullscreen() async {
    try {
      if (_isFullscreen) {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
        );
      } else {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
        );
      }
      setState(() => _isFullscreen = !_isFullscreen);
    } catch (e) {
      debugPrint('Error toggling fullscreen: $e');
    }
  }

  // --- Exit ---

  Future<void> _exitApp() async {
    if (_isPlaying) {
      _togglePlay();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // --- Gesture Handling ---

  void _handleTap() {
    if (_imageList.isEmpty) return;
    
    // Single tap: toggle play/pause
    _togglePlay();
  }

  void _handleDoubleTap() {
    if (_imageList.isEmpty) return;
    
    // Double tap: toggle fullscreen
    _toggleFullscreen();
  }

  void _handleSwipeLeft() {
    if (_imageList.isEmpty) return;
    
    // Swipe left: next image
    _showNext();
    _startUiTimer(); // Reset UI hide timer
  }

  void _handleSwipeRight() {
    if (_imageList.isEmpty) return;
    
    // Swipe right: previous image
    _showPrevious();
    _startUiTimer(); // Reset UI hide timer
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.space) {
              _togglePlay();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _showNext();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _showPrevious();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              if (_isPlaying) {
                _togglePlay();
              } else {
                _exitApp();
              }
            } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
              _toggleFullscreen();
            }
          }
        },
        child: MouseRegion(
          onHover: (_) => _onInteraction(),
          cursor: _showUI ? SystemMouseCursors.basic : SystemMouseCursors.none,
          child: GestureDetector(
            onTap: _handleTap,
            onDoubleTap: _handleDoubleTap,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! > 0) {
                  _handleSwipeRight();
                } else if (details.primaryVelocity! < 0) {
                  _handleSwipeLeft();
                }
              }
            },
            child: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Image Display (centered, maintains aspect ratio)
                  if (_imageList.isNotEmpty)
                    ImageDisplay(
                      imagePath: _imageList[_currentIndex],
                      fit: BoxFit.contain,
                    )
                  else
                    _buildEmptyState(),

                  // 2. Info Bar (bottom-left)
                  if (_imageList.isNotEmpty && _showUI)
                    InfoBar(
                      currentIndex: _currentIndex + 1,
                      totalImages: _imageList.length,
                      imagePath: _imageList[_currentIndex],
                    ),

                  // 3. Pause Overlay (center)
                  if (!_isPlaying && _imageList.isNotEmpty && _showUI)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(20, 20, 20, 0.8),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: AppConstants.borderColor),
                        ),
                        child: const Text(
                          AppConstants.pauseLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // 4. Control Bar (top-center)
                  AnimatedOpacity(
                    opacity: _showUI ? 1.0 : 0.0,
                    duration: AppConstants.fadeAnimationDuration,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppConstants.infoBarPadding,
                        ),
                        child: ControlBar(
                          interval: _settings.interval,
                          shuffle: _settings.shuffle,
                          isPlaying: _isPlaying,
                          intervalOptions: AppConstants.intervalOptions,
                          onIntervalChanged: (newValue) {
                            setState(() {
                              _settings = _settings.copyWith(
                                interval: newValue,
                              );
                              _saveSettings();
                              if (_isPlaying) _startSlideTimer();
                            });
                          },
                          onShuffleChanged: (newValue) {
                            setState(() {
                              _settings = _settings.copyWith(
                                shuffle: newValue,
                              );
                              _saveSettings();
                              _applySorting();
                            });
                          },
                          onAddFiles: _pickFiles,
                          onAddFolder: _pickFolder,
                          onExit: _exitApp,
                        ),
                      ),
                    ),
                  ),

                  // 5. Loading indicator
                  if (_isLoading)
                    const Center(
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white54,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.white30,
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.noImagesMessage,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.noImagesSubtitle,
            style: TextStyle(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}
