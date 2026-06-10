import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kai_slideshow/utils/constants.dart';

/// Control bar widget with slideshow controls
/// Glassmorphism effect with blur
class ControlBar extends StatelessWidget {
  final int interval;
  final bool shuffle;
  final bool isPlaying;
  final List<int> intervalOptions;
  final Function(int) onIntervalChanged;
  final Function(bool) onShuffleChanged;
  final Function onAddFiles;
  final Function onAddFolder;
  final Function onExit;

  const ControlBar({
    super.key,
    required this.interval,
    required this.shuffle,
    required this.isPlaying,
    required this.intervalOptions,
    required this.onIntervalChanged,
    required this.onShuffleChanged,
    required this.onAddFiles,
    required this.onAddFolder,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    // Use full width in portrait mode, constrained width in landscape
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final maxWidth = isPortrait ? double.infinity : 900.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: AppConstants.controlBarHeight,
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 25),
          decoration: BoxDecoration(
            color: AppConstants.controlBarColor,
            border: Border.all(color: AppConstants.borderColor),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Row(
            children: [
              // Interval dropdown
              const Text(
                AppConstants.intervalLabel,
                style: TextStyle(color: AppConstants.textColor, fontSize: 14),
              ),
              const SizedBox(width: 10),
              DropdownButton<int>(
                dropdownColor: const Color(0xFF444444),
                value: interval,
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white),
                items: intervalOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    onIntervalChanged(newValue);
                  }
                },
              ),
              const SizedBox(width: 20),
              // Shuffle checkbox
              Row(
                children: [
                  Checkbox(
                    value: shuffle,
                    activeColor: Colors.blue,
                    onChanged: (bool? value) {
                      onShuffleChanged(value ?? true);
                    },
                  ),
                  const Text(
                    AppConstants.shuffleLabel,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const Spacer(),
              // Add Files button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.addButtonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonBorderRadius,
                    ),
                  ),
                ),
                onPressed: () => onAddFiles(),
                child: const Text('Add Files'),
              ),
              const SizedBox(width: 10),
              // Add Folder button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.addButtonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonBorderRadius,
                    ),
                  ),
                ),
                onPressed: () => onAddFolder(),
                child: const Text('Add Folder'),
              ),
              const SizedBox(width: 10),
              // Exit button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.exitButtonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonBorderRadius,
                    ),
                  ),
                ),
                onPressed: () => onExit(),
                child: const Text(
                  AppConstants.exit,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
