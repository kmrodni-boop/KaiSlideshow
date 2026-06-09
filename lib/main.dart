import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const KaiSlideshowApp());
}

class KaiSlideshowApp extends StatelessWidget {
  const KaiSlideshowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kai Slideshow',
      debugShowCheckedModeBanner: false,
      // Setter bakgrunnen til svart, akkurat som din setStyleSheet
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const SlideshowScreen(),
    );
  }
}

class SlideshowScreen extends StatefulWidget {
  const SlideshowScreen({super.key});

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  // Tilstander (State)
  final List<String> _imageList = [];
  int _currentIndex = 0;
  int _interval = 5;
  bool _shuffle = true;
  bool _isPlaying = false;
  bool _showUI = true;

  // Timere (Tilsvarer dine QTimer-objekter)
  Timer? _slideTimer;
  Timer? _uiTimer;

  // Fokus for tastatur (For piltaster og mellomrom)
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startUiTimer();
    // Be om fokus for å fange opp tastetrykk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _uiTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  // --- Logikk ---

  Future<void> _pickFolder() async {
    // Tilsvarer din select_folders_dialog()
      String? directoryPath = await FilePicker.platform.getDirectoryPath();    if (directoryPath != null) {
      final dir = Directory(directoryPath);
      final files = dir.listSync(recursive: true);
      
      List<String> newImages = [];
      for (var file in files) {
        if (file is File) {
          final ext = file.path.toLowerCase();
          if (ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.webp') || ext.endsWith('.bmp')) {
            newImages.add(file.path);
          }
        }
      }

      setState(() {
        _imageList.addAll(newImages);
        _applySorting();
        if (_imageList.isNotEmpty && !_isPlaying) {
          _togglePlay();
        }
      });
    }
  }

  void _applySorting() {
    // Din apply_sorting logikk
    setState(() {
      if (_shuffle) {
        _imageList.shuffle(Random());
      } else {
        _imageList.sort();
      }
      _currentIndex = 0;
    });
  }

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

  void _togglePlay() {
    setState(() {
      if (_isPlaying) {
        _slideTimer?.cancel();
        _isPlaying = false;
        _showUI = true;
        _uiTimer?.cancel(); // Stopper skjuling av meny når på pause
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
      _slideTimer = Timer.periodic(Duration(seconds: _interval), (timer) {
        _showNext();
      });
    }
  }

  void _startUiTimer() {
    // Tilsvarer din mouse_timer på 2-3 sekunder
    _uiTimer?.cancel();
    _uiTimer = Timer(const Duration(seconds: 3), () {
      if (_isPlaying) {
        setState(() => _showUI = false);
      }
    });
  }

  void _onInteraction() {
    // Våkner UI ved bevegelse/trykk (Tilsvarer mouseMoveEvent)
    if (!_showUI) {
      setState(() => _showUI = true);
    }
    _startUiTimer();
  }

  // --- UI Bygging ---

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
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
            SystemNavigator.pop(); // Avslutter appen
          }
        }
      },
      child: MouseRegion(
        onHover: (_) => _onInteraction(),
        cursor: _showUI ? SystemMouseCursors.basic : SystemMouseCursors.none,
        child: GestureDetector(
          onTap: _onInteraction,
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Selve bildet (Tilsvarer QLabel med QPixmap)
                if (_imageList.isNotEmpty)
                  Image.file(
                    File(_imageList[_currentIndex]),
                    fit: BoxFit.contain,
                  )
                else
                  const Center(child: Text("Ingen bilder valgt", style: TextStyle(color: Colors.white54))),

                // 2. Info Bar (Tilsvarer din info_bar nede i hjørnet)
                if (_imageList.isNotEmpty && _showUI)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(12)),
                      ),
                      child: Text(
                        "${_currentIndex + 1} / ${_imageList.length}   •   ${_imageList[_currentIndex].split(Platform.pathSeparator).last}",
                        style: const TextStyle(color: Color(0xFFDDDDDD)),
                      ),
                    ),
                  ),

                // 3. Pause ikon (Tilsvarer din pause_label med 50px font)
                if (!_isPlaying && _imageList.isNotEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(20, 20, 20, 0.8), // rgba(20, 20, 20, 200)
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFF444444)),
                      ),
                      child: const Text(
                        "Ⅱ PAUSE",
                        style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // 4. Glassmorphism Meny Bar (Tilsvarer din menu_bar QFrame)
                AnimatedOpacity(
                  opacity: _showUI ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 80,
                            constraints: const BoxConstraints(maxWidth: 800),
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(35, 35, 35, 0.9), // rgba(35, 35, 35, 230)
                              border: Border.all(color: const Color(0xFF555555)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Text("Intervall:", style: TextStyle(color: Color(0xFFEEEEEE), fontSize: 14)),
                                const SizedBox(width: 10),
                                DropdownButton<int>(
                                  dropdownColor: const Color(0xFF444444),
                                  value: _interval,
                                  underline: const SizedBox(),
                                  style: const TextStyle(color: Colors.white),
                                  items: [2, 3, 5, 10, 20, 30].map((int value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text(value.toString()),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _interval = newValue;
                                        if (_isPlaying) _startSlideTimer();
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 20),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _shuffle,
                                      activeColor: Colors.blue,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _shuffle = value ?? true;
                                          _applySorting();
                                        });
                                      },
                                    ),
                                    const Text("Tilfeldig", style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2980B9), // Din Legg til-farge
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _pickFolder,
                                  child: const Text("Legg til mapper"),
                                ),
                                const SizedBox(width: 15),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC0392B), // Din Avslutt-farge
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => SystemNavigator.pop(),
                                  child: const Text("Avslutt", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}