enum DefaultType {
  mood,
  sounds,
  soundboard,
}

extension DefaultTypeExtension on DefaultType {
  String get value {
    switch (this) {
      case DefaultType.mood:
        return "Mood";
      case DefaultType.sounds:
        return "Sounds";
      case DefaultType.soundboard:
        return "Soundboard";
    }
  }

  static DefaultType? fromString(String defaultType) {
    switch (defaultType) {
      case "Mood":
        return DefaultType.mood;
      case "Sounds":
        return DefaultType.sounds;
      case "Soundboard":
        return DefaultType.soundboard;
      default:
        return null;
    }
  }
}
