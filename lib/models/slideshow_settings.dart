/// Slideshow settings model for persistence
class SlideshowSettings {
  final int interval;
  final bool shuffle;

  const SlideshowSettings({
    this.interval = 5,
    this.shuffle = true,
  });

  /// Default settings
  static const defaultSettings = SlideshowSettings();

  /// Create from JSON (for SharedPreferences)
  factory SlideshowSettings.fromJson(Map<String, dynamic> json) {
    return SlideshowSettings(
      interval: json['interval'] as int? ?? 5,
      shuffle: json['shuffle'] as bool? ?? true,
    );
  }

  /// Convert to JSON (for SharedPreferences)
  Map<String, dynamic> toJson() => {
        'interval': interval,
        'shuffle': shuffle,
      };

  /// Copy with new values
  SlideshowSettings copyWith({
    int? interval,
    bool? shuffle,
  }) {
    return SlideshowSettings(
      interval: interval ?? this.interval,
      shuffle: shuffle ?? this.shuffle,
    );
  }
}
