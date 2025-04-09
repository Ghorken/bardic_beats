import 'package:flutter/material.dart';
import 'package:bardic_beats/enums/column_type_enum.dart';

class Themes {
  // Generic
  static const String appName = "Bardic Beats";
  static const List<String> playableFiles = [
    ".mp3",
    ".mp4",
    ".m4a",
  ];

  // Spacing
  static const double adBarHeight = 50.0;
  static const double selectColorRowHeight = 20.0;
  static const double padding = 10.0;
  static const double tutorialPadding = 15.0;
  static const double margin = 10.0;
  static const double tutorialMargin = 5.0;
  static const double headerSmallPadding = 5.0;
  static const double spacerWidth = 10.0;
  static const double spacerHeight = 10.0;
  static const double tutorialTitleTopPadding = 50.0;
  static const double tutorialTextTopPadding = 10.0;

  // Buttons
  static const double borderRadius = 10.0;
  static const double iconSize = 24.0;
  static const double buttonSize = 25.0;
  static const double buttonHeight = 40.0;
  static const double buttonMargin = 10.0;
  static const double buttonPadding = 5.0;
  static const double buttonPaddingMedium = 10.0;
  static const double buttonElevation = 8.0;
  static const int dropdownButtonElevation = 16;

  // Fonts
  static const double settingsFontSize = 18.0;
  static const double creditsFontSize = 15.0;
  static const double toastFontSize = 15.0;
  static const double tutorialTitleFontSize = 20.0;
  static const double tutorialTextFontSize = 18.0;
  static const double headerFontSize = 20.0;
  static const double columnFontSize = 15.0;
  static const double columnSettingsFontSize = 18.0;
  static const double underlineHeight = 2;

  // Assets
  static const String singleBorderAsset = "assets/Btn/btn-single-border.png";
  static const String doubleBorderAsset = "assets/Btn/btn-double-border.png";
  static const String backgroundAssets = "assets/Background/";
  static const String githubAssets = "assets/Github/";

  // Images
  static const double settingsBackgroundImageWidth = 100.0;
  static const double settingsBackgroundImageHeight = 75.0;

  // Colors
  static const int whiteValue = 4294638330;
  static const int blackValue = 4280361249;
  static const int greenValue = 4279983648;
  static const int yellowValue = 4294956367;

  // Icone
  static Map<String, IconData> icons = {
    ColumnType.directoryColumn.value: Icons.folder_rounded,
    ColumnType.defaultColumn.value: Icons.system_update_rounded,
    ColumnType.cloudColumn.value: Icons.language_rounded,
    ColumnType.bardPublicColumn.value: Icons.record_voice_over_rounded,
  };

  // Tutorial
  static const int rapidColumnScroll = 50;
  static const int rapidDelayAfterScroll = 50;
}
