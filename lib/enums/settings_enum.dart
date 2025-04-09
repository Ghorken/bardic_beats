enum Settings {
  screenAlwaysOn,
  mainColor,
  fontColor,
  backgroundImg,
  backgroundColor,
  showDefaultTutorial,
  showDirectoryTutorial,
  showCloudTutorial,
  showBardPublicTutorial,
  language,
}

extension SettingsExtension on Settings {
  String get value {
    switch (this) {
      case Settings.screenAlwaysOn:
        return "ScreenAlwaysOn";
      case Settings.mainColor:
        return "MainColor";
      case Settings.fontColor:
        return "FontColor";
      case Settings.backgroundImg:
        return "BackgroundImg";
      case Settings.backgroundColor:
        return "BackgroundColor";
      case Settings.showDefaultTutorial:
        return "ShowDefaultTutorial";
      case Settings.showDirectoryTutorial:
        return "ShowDirectoryTutorial";
      case Settings.showCloudTutorial:
        return "ShowCloudTutorial";
      case Settings.showBardPublicTutorial:
        return "ShowBardPublicTutorial";
      case Settings.language:
        return "Language";
    }
  }
}
