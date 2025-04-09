import 'dart:convert';
import 'dart:io';

import 'package:bardic_beats/playify/playify.dart';
import 'package:bardic_beats/playify/playlist.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';

import 'package:bardic_beats/enums/column_characteristics_enum.dart';
import 'package:bardic_beats/enums/column_type_enum.dart';
import 'package:bardic_beats/utility/themes.dart';
import 'package:bardic_beats/enums/settings_enum.dart';
import 'package:bardic_beats/enums/operation_enum.dart';
import 'package:bardic_beats/managers/shared_preferences_manager.dart';

class FilesProvider with ChangeNotifier {
  // Variabili condivise
  final Map<String, List<dynamic>> _files = {};
  final Map<String, List<String>> _columnCharacteristics = {};
  List<String> _backgroundImages = [];
  final List<String> _customBackgroundImages = [];
  bool _screenAlwaysOn = true;
  int _mainColor = Themes.greenValue;
  int _fontColor = Themes.whiteValue;
  String _backgroundImg = "assets/Background/Desert-Oasis-Town.jpg";
  int _backgroundColor = Themes.yellowValue;
  bool _showDefaultTutorial = true;
  bool _showDirectoryTutorial = true;
  bool _showCloudTutorial = true;
  bool _showBardPublicTutorial = true;
  final Map<String, String> _appFontColors = {"black": "${Themes.blackValue}", "white": "${Themes.whiteValue}"};
  double _loadedBackgroundHeight = 0.0;
  double _loadedBackgroundWidth = 0.0;
  String _language = "en";

  Map<String, List<dynamic>> get files => _files;
  Map<String, List<String>> get columnCharacteristics => _columnCharacteristics;
  List<String> get backgroundImages => _backgroundImages;
  bool get screenAlwaysOn => _screenAlwaysOn;
  int get mainColor => _mainColor;
  int get fontColor => _fontColor;
  String get backgroundImg => _backgroundImg;
  int get backgroundColor => _backgroundColor;
  bool get showDefaultTutorial => _showDefaultTutorial;
  bool get showDirectoryTutorial => _showDirectoryTutorial;
  bool get showCloudTutorial => _showCloudTutorial;
  bool get showBardPublicTutorial => _showBardPublicTutorial;
  Map<String, String> get appFontColors => _appFontColors;
  double get loadedBackgroundHeight => _loadedBackgroundHeight;
  double get loadedBackgroundWidth => _loadedBackgroundWidth;
  String get language => _language;

  /// Imposta lo schermo sempre acceso o meno
  void setScreenAlwaysOn(bool screenAlwaysOn) {
    _screenAlwaysOn = screenAlwaysOn;
    SharedPreferencesManager.updateKV(Settings.screenAlwaysOn.value, Operation.update, _screenAlwaysOn);
    notifyListeners();
  }

  /// Imposta il colore principale
  void setMainColor(int mainColor) {
    _mainColor = mainColor;
    SharedPreferencesManager.updateKV(Settings.mainColor.value, Operation.update, _mainColor);
    notifyListeners();
  }

  /// Imposta il colore del font
  void setFontColor(int fontColor) {
    _fontColor = fontColor;
    SharedPreferencesManager.updateKV(Settings.fontColor.value, Operation.update, _fontColor);
    notifyListeners();
  }

  /// Imposta l'immagine di background
  void setBackgroundImg(String backgroundImg) {
    _backgroundImg = backgroundImg;
    SharedPreferencesManager.updateKV(Settings.backgroundImg.value, Operation.update, _backgroundImg);
    notifyListeners();
  }

  /// Imposta il colore di background
  void setBackgroundColor(int backgroundColor) {
    _backgroundColor = backgroundColor;
    SharedPreferencesManager.updateKV(Settings.backgroundColor.value, Operation.update, _backgroundColor);
  }

  /// Imposta la visualizzuazione del tutorial delle colonne di default
  void setShowDefaultTutorial(bool showDefaultTutorial) {
    _showDefaultTutorial = showDefaultTutorial;
    SharedPreferencesManager.updateKV(Settings.showDefaultTutorial.value, Operation.update, _showDefaultTutorial);
  }

  /// Imposta la visualizzuazione del tutorial delle colonne directory
  void setShowDirectoryTutorial(bool showDirectoryTutorial) {
    _showDirectoryTutorial = showDirectoryTutorial;
    SharedPreferencesManager.updateKV(Settings.showDirectoryTutorial.value, Operation.update, _showDirectoryTutorial);
  }

  /// Imposta la visualizzuazione del tutorial delle colonne cloud
  void setShowCloudTutorial(bool showCloudTutorial) {
    _showCloudTutorial = showCloudTutorial;
    SharedPreferencesManager.updateKV(Settings.showCloudTutorial.value, Operation.update, _showCloudTutorial);
  }

  /// Imposta la visualizzuazione del tutorial delle colonne bardo/pubblico
  void setShowBardPublicTutorial(bool showBardPublicTutorial) {
    _showBardPublicTutorial = showBardPublicTutorial;
    SharedPreferencesManager.updateKV(Settings.showBardPublicTutorial.value, Operation.update, _showBardPublicTutorial);
  }

  /// Imposta la lingua
  void setLanguage(String language) {
    _language = language;
    SharedPreferencesManager.updateKV(Settings.language.value, Operation.update, _language);
    notifyListeners();
  }

  /// Recupera le liste di file
  void getFilesList({String? columnId}) async {
    SharedPreferences sharedPreferences = await SharedPreferencesManager.getSharedPreferencesInstance();

    List<String> columnIdsToProcess;

    // Determina quali colonne aggiornare
    if (columnId != null) {
      // Se è stato specificato un id crea una lista con solo quell'id
      columnIdsToProcess = [columnId];
    } else {
      // Se non è stato specificato un id recupera la lista di tutti gli id
      columnIdsToProcess = sharedPreferences.getStringList("ColumnsId") ?? [];
    }

    // Recupera i file di tutte le colonne interessate contemporaneamente
    await Future.wait(columnIdsToProcess.map((String colId) async {
      List<String> columnCharacteristics = sharedPreferences.getStringList(colId)!;
      ColumnType columnType = ColumnTypeExtension.fromString(columnCharacteristics[ColumnCharacteristic.columnType.position])!;

      if (columnType == ColumnType.directoryColumn) {
        String directoryPath = columnCharacteristics[ColumnCharacteristic.directoryPath.position];
        String playlistId = columnCharacteristics[ColumnCharacteristic.playlistId.position];
        _files[colId] = await getFiles(directoryPath: directoryPath, playlistId: playlistId, columnType: columnType);
      } else if (columnType == ColumnType.defaultColumn) {
        String defaultType = columnCharacteristics[ColumnCharacteristic.defaultType.position];
        _files[colId] = await getFiles(defaultType: defaultType, columnType: columnType);
      } else if (columnType == ColumnType.cloudColumn || columnType == ColumnType.bardPublicColumn) {
        List<String> urlsList = columnCharacteristics[ColumnCharacteristic.urlsList.position]
            .substring(1, columnCharacteristics[ColumnCharacteristic.urlsList.position].length - 1)
            .split(", ")
            .toList();
        _files[colId] = await getFiles(urlsList: urlsList, columnType: columnType);
      }

      _columnCharacteristics[colId] = columnCharacteristics;

      // Notifica i cambiamenti ai listener
      notifyListeners();
    }));
  }

  /// Elimina una colonna
  void deleteColumn({required String columnId}) {
    _files.remove(columnId);
    _columnCharacteristics.remove(columnId);

    // Notifica i cambiamenti ai listener
    notifyListeners();
  }

  /// Restituisce l`elenco dei file audio nella sotto cartella specificata
  Future<List<dynamic>> getFiles({String? directoryPath, String? playlistId, String? defaultType, List<String>? urlsList, required ColumnType columnType}) async {
    List<dynamic> files = List.empty(growable: true);

    // Se si stanno popolando le colonne di canzoni dell'utente agisce in base alla piattaforma
    if (columnType == ColumnType.directoryColumn) {
      // Richiede i permessi di accedere ai file del device
      if (await Permission.storage.request().isGranted) {
        if (Platform.isIOS) {
          // Recupera le canzoni dalla playlist selezionata
          Playify playify = Playify();
          List<Playlist>? playlists = await playify.getPlaylists();
          files = playlists!.firstWhere((Playlist playlist) => playlist.playlistID == playlistId).songs;
        } else {
          // Prende dalla directory solo i file le cui estensioni risultano nell'elenco
          files = Directory(directoryPath!).listSync().cast<File>().where((element) => Themes.playableFiles.contains(extension(basename(element.path)))).toList();
        }
      }
    }

    // Se si stanno popolando le colonne di default
    if (columnType == ColumnType.defaultColumn) {
      // AssetManifest contiene la lista di tutto ciò che è in assets
      String assets = await rootBundle.loadString('AssetManifest.json');

      // Recupera solo i file con le estensioni audio
      Map<String, dynamic> jsonAssets = json.decode(assets) as Map<String, dynamic>;
      List<String> get = jsonAssets.keys.where((String element) => Themes.playableFiles.contains(extension(basename(element)))).toList();
      for (String element in get) {
        if (element.contains("Default_music/${defaultType!}")) {
          files.add(File(element));
        }
      }
    }

    // Se si stanno popolando le colonne cloud si usano solo i file validi
    if (columnType == ColumnType.cloudColumn || columnType == ColumnType.bardPublicColumn) {
      files.addAll(urlsList!);
    }
    return files;
  }

  /// Recupera la lista di settings generici
  void getSettings() async {
    SharedPreferences sharedPreferences = await SharedPreferencesManager.getSharedPreferencesInstance();
    if (sharedPreferences.getBool(Settings.screenAlwaysOn.value) != null) {
      _screenAlwaysOn = sharedPreferences.getBool(Settings.screenAlwaysOn.value)!;
    }
    if (sharedPreferences.getInt(Settings.mainColor.value) != null) {
      _mainColor = sharedPreferences.getInt(Settings.mainColor.value)!;
    }
    if (sharedPreferences.getInt(Settings.fontColor.value) != null) {
      _fontColor = sharedPreferences.getInt(Settings.fontColor.value)!;
    }
    if (sharedPreferences.getString(Settings.backgroundImg.value) != null) {
      _backgroundImg = sharedPreferences.getString(Settings.backgroundImg.value)!;
      if (_backgroundImg != "none") {
        ByteData img = await rootBundle.load(_backgroundImg);
        var decodedImage = await decodeImageFromList(img.buffer.asUint8List());
        _loadedBackgroundHeight = decodedImage.height.toDouble();
        _loadedBackgroundWidth = decodedImage.width.toDouble();
      }
    }
    if (sharedPreferences.getInt(Settings.backgroundColor.value) != null) {
      _backgroundColor = sharedPreferences.getInt(Settings.backgroundColor.value)!;
    }
    if (sharedPreferences.getBool(Settings.showDefaultTutorial.value) != null) {
      _showDefaultTutorial = sharedPreferences.getBool(Settings.showDefaultTutorial.value)!;
    }
    if (sharedPreferences.getString(Settings.language.value) != null) {
      _language = sharedPreferences.getString(Settings.language.value)!;
    }
    notifyListeners();
  }

  /// Recupera le immagini di sfondo
  void getBackgroundImages() async {
    String manifestContent = await rootBundle.loadString('AssetManifest.json');
    Map<String, dynamic> manifestMap = json.decode(manifestContent) as Map<String, dynamic>;
    _backgroundImages = manifestMap.keys.where((String key) => key.contains(Themes.backgroundAssets)).toList();
    _backgroundImages.add("none");
    _backgroundImages.addAll(_customBackgroundImages);

    notifyListeners();
  }

  /// Aggiunge un'immagine personalizzata alla lista
  void addBackgroundImage(String imgPath) {
    _customBackgroundImages.add(imgPath);

    getBackgroundImages();
  }

  /// Elimina l'immagine personalizzata selezionata
  void deleteBackgroundImage(String imgPath) {
    _customBackgroundImages.remove(imgPath);

    getBackgroundImages();
  }
}
