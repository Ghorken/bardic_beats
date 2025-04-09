import 'dart:io';

import 'package:bardic_beats/playify/playify.dart';
import 'package:bardic_beats/playify/playlist.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nanoid/nanoid.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:bardic_beats/dialogs/playlist_selection_dialog.dart';
import 'package:bardic_beats/files_provider.dart';
import 'package:bardic_beats/enums/column_characteristics_enum.dart';
import 'package:bardic_beats/utility/column_dialog_functions.dart';
import 'package:bardic_beats/enums/column_type_enum.dart';
import 'package:bardic_beats/enums/operation_enum.dart';
import 'package:bardic_beats/utility/string_extension.dart';
import 'package:bardic_beats/utility/themes.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class DirectoryColumnSettingsDialog extends StatefulWidget {
  final bool newCol;
  final String? columnId;

  const DirectoryColumnSettingsDialog({super.key, required this.newCol, this.columnId});

  @override
  State<DirectoryColumnSettingsDialog> createState() => _DirectoryColumnSettingsDialog();
}

class _DirectoryColumnSettingsDialog extends State<DirectoryColumnSettingsDialog> {
  late bool newCol;

  late String colTitle;
  late String columnId;
  late String directoryPath;
  late String playlistId;
  late int columnColor;
  late String columnName;
  late int fontColor;
  late bool hasLoop;
  late double columnVolume;
  late bool hasFading;
  late TextEditingController titleEditingController;
  late FilesProvider filesProvider;

  bool isEditingTitle = false;
  List<TargetFocus> targets = [];
  // Evita che un rebuild della colonna scateni nuovamente il tutorial
  bool mustShowTutorial = false;
  Map<String, GlobalKey> keyTargets = {
    "headerKey": GlobalKey(),
    "chooseDirectoryKey": GlobalKey(),
    "colorKey": GlobalKey(),
    "nameKey": GlobalKey(),
    "fontKey": GlobalKey(),
    "loopKey": GlobalKey(),
    "fadeKey": GlobalKey(),
    "duplicateKey": GlobalKey(),
    "updateKey": GlobalKey(),
    "deleteKey": GlobalKey(),
    "saveKey": GlobalKey(),
  };
  bool loading = false;

  Playify playify = Playify();

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    newCol = widget.newCol;

    filesProvider = Provider.of<FilesProvider>(context, listen: false);

    columnId = widget.columnId ?? customAlphabet("1234567890abcdefghijklmnopqrstuvwxy", 10);
    columnVolume = 5.0;
    mustShowTutorial = filesProvider.showDirectoryTutorial;

    if (newCol) {
      // Se si sta aprendo una colonna nuova pre-popola i campi con i dati standard
      colTitle = translate("popup.new_directory_column");
      columnName = translate("popup.column_name");
      if (Platform.isIOS) {
        directoryPath = translate("popup.playlist");
      } else {
        directoryPath = translate("popup.directory_path");
      }
      playlistId = "0";
      columnColor = filesProvider.mainColor;
      fontColor = filesProvider.fontColor;
      hasLoop = true;
      hasFading = true;
    } else {
      // Se si sta aprendo una colonna esistente pre-popola i campi con i dati in memoria
      List<String> columnCharacteristics = filesProvider.columnCharacteristics[columnId]!;
      directoryPath = columnCharacteristics[ColumnCharacteristic.directoryPath.position];
      playlistId = columnCharacteristics[ColumnCharacteristic.playlistId.position];
      columnColor = int.parse(columnCharacteristics[ColumnCharacteristic.columnColor.position]);
      columnName = columnCharacteristics[ColumnCharacteristic.columnName.position];
      fontColor = int.parse(columnCharacteristics[ColumnCharacteristic.fontColor.position]);
      hasLoop = columnCharacteristics[ColumnCharacteristic.hasLoop.position].toBoolean();
      hasFading = columnCharacteristics[ColumnCharacteristic.hasFading.position].toBoolean();
      colTitle = translate("popup.edit_directory_column");
    }
  }

  @override
  Widget build(BuildContext context) {
    // La visualizzazione del tutorial viene fatta nel postFrameCallback in modo che la colonna sia già tutta disegnata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mustShowTutorial) {
        targets = createTutorial(
          columnType: ColumnType.directoryColumn,
          keyTargets: keyTargets,
          fontColor: fontColor,
          newCol: newCol,
        );

        showTutorial(
          context: context,
          targets: targets,
          keyTargets: keyTargets,
          scrollController: scrollController,
          columnType: ColumnType.directoryColumn,
        );

        filesProvider.setShowDirectoryTutorial(false);
        setState(() {
          mustShowTutorial = false;
        });
      }
    });
    NavigatorState navigator = Navigator.of(context);
    titleEditingController = TextEditingController(text: columnName);

    return AlertDialog(
      title: Container(
        key: keyTargets["headerKey"],
        padding: const EdgeInsets.all(Themes.columnFontSize),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(columnColor),
          image: const DecorationImage(
            image: AssetImage(Themes.singleBorderAsset),
            fit: BoxFit.fill,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                colTitle,
                style: TextStyle(
                  fontSize: Themes.headerFontSize,
                  color: Color(fontColor),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              color: Color(fontColor),
              onPressed: () {
                targets = createTutorial(
                  columnType: ColumnType.directoryColumn,
                  keyTargets: keyTargets,
                  fontColor: fontColor,
                  newCol: newCol,
                );

                showTutorial(
                  context: context,
                  targets: targets,
                  keyTargets: keyTargets,
                  scrollController: scrollController,
                  columnType: ColumnType.directoryColumn,
                );
              },
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gestisce la scelta di una nuova directory
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_rounded),
                  color: Colors.grey,
                  onPressed: () {
                    pickDirectory();
                  },
                ),
                Flexible(
                  key: keyTargets["chooseDirectoryKey"],
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      pickDirectory();
                    },
                    child: Text(
                      directoryPath,
                      style: const TextStyle(color: Colors.black, fontSize: Themes.columnSettingsFontSize),
                    ),
                  ),
                ),
              ],
            ),
            ...genericColumnSettings(
              columnType: ColumnType.directoryColumn,
              keyTargets: keyTargets,
              columnColor: columnColor,
              context: context,
              choosedColorCallback: (int choosedColor) {
                setState(() {
                  columnColor = choosedColor;
                });
              },
              titleEditingController: titleEditingController,
              choosedColorName: (String choosedName) {
                columnName = choosedName;
              },
              fontColor: fontColor,
              choosedFontColorCallback: (int choosedFontColor) {
                setState(() {
                  fontColor = choosedFontColor;
                });
              },
              hasLoop: hasLoop,
              choosedLoopCallback: (bool choosedLoop) {
                setState(() {
                  hasLoop = choosedLoop;
                });
              },
              hasFading: hasFading,
              choosedFadeCallback: (bool choosedFading) {
                setState(() {
                  hasFading = choosedFading;
                });
              },
              newCol: newCol,
              duplicateCallback: () {
                // Duplica la colonna e chiude il popup
                Map<ColumnCharacteristic, String> characteristicsMap = {
                  ColumnCharacteristic.directoryPath: directoryPath,
                  ColumnCharacteristic.columnColor: columnColor.toString(),
                  ColumnCharacteristic.columnName: columnName,
                  ColumnCharacteristic.fontColor: fontColor.toString(),
                  ColumnCharacteristic.playlistId: playlistId,
                  ColumnCharacteristic.hasLoop: hasLoop.toString(),
                  ColumnCharacteristic.columnVolume: columnVolume.toString(),
                  ColumnCharacteristic.hasFading: hasFading.toString(),
                  ColumnCharacteristic.columnType: ColumnType.directoryColumn.value,
                };
                duplicateCol(characteristicsMap, filesProvider);
                navigator.pop();
              },
              updateCallback: () {
                // Aggiorna la colonna e chiude il popup
                updateCol(columnId, filesProvider);
                navigator.pop();
              },
              deleteCallback: () {
                // Cancella la colonna e chiude il popup
                deleteCol(columnId, filesProvider);
                navigator.pop(Operation.delete);
              },
            ),
          ],
        ),
      ),
      actions: [
        // I due pulsanti di azione del dialog
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(
              onPressed: () {
                // Chiude il popup
                navigator.pop();
              },
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: Themes.columnSettingsFontSize),
                foregroundColor: Colors.black,
              ),
              child: Text(translate("popup.abort")),
            ),
            Stack(
              children: [
                if (loading) const CircularProgressIndicator(),
                TextButton(
                  key: keyTargets["saveKey"],
                  onPressed: () async {
                    setState(() {
                      loading = true;
                    });

                    if (await permissionsGranted()) {
                      final List<dynamic> files;
                      if (Platform.isIOS) {
                        Playify playify = Playify();
                        List<Playlist>? playlists = await playify.getPlaylists();
                        files = playlists!.firstWhere((Playlist playlist) => playlist.playlistID == playlistId).songs;
                      } else {
                        files = Directory(directoryPath)
                            .listSync()
                            .cast<File>()
                            .where((element) => Themes.playableFiles.contains(path.extension(path.basename(element.path))))
                            .toList();
                      }
                      if (files.isEmpty) {
                        Fluttertoast.showToast(
                          msg: translate("popup.no_files", args: {"audio_types": Themes.playableFiles.join(", ")}),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.SNACKBAR,
                          timeInSecForIosWeb: 1,
                          fontSize: Themes.toastFontSize,
                        );

                        setState(() {
                          loading = false;
                        });
                      } else {
                        // Salva la colonna e chiude il popup
                        Map<ColumnCharacteristic, String> characteristicsMap = {
                          ColumnCharacteristic.directoryPath: directoryPath,
                          ColumnCharacteristic.columnColor: columnColor.toString(),
                          ColumnCharacteristic.columnName: columnName,
                          ColumnCharacteristic.fontColor: fontColor.toString(),
                          ColumnCharacteristic.playlistId: playlistId,
                          ColumnCharacteristic.hasLoop: hasLoop.toString(),
                          ColumnCharacteristic.columnVolume: columnVolume.toString(),
                          ColumnCharacteristic.hasFading: hasFading.toString(),
                          ColumnCharacteristic.columnType: ColumnType.directoryColumn.value,
                        };
                        await FirebaseAnalytics.instance.logEvent(
                          name: "new_column",
                          parameters: {
                            "column_type": ColumnType.directoryColumn.value,
                          },
                        );
                        saveColumn(newCol, columnId, characteristicsMap, filesProvider);
                        navigator.pop();
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: Themes.columnSettingsFontSize),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(translate("popup.save")),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  /// Gestisce il directoryPicker
  Future<void> pickDirectory() async {
    if (Platform.isIOS) {
      // Recupera tutte le playlist
      final List<Playlist>? playlists = await playify.getPlaylists();

      // Crea una dialog a cui passare tutte le playlist per mostrarle
      //  e che valorizza il nome e l'id della playlist
      if (mounted) {
        showDialog<List<String>>(
          context: context,
          builder: (BuildContext context) {
            return PlaylistSelectionDialog(playlists: playlists!, dirColor: columnColor, fontColor: fontColor);
          },
        ).then((List<String>? val) {
          // Salva l'id della playlist al posto del path e imposta il nome della colonna in base alla directory scelta
          if (val != null) {
            if (val[0].isNotEmpty && val[1].isNotEmpty) {
              setState(() {
                directoryPath = val[0];
                playlistId = val[1];
                columnName = path.basename(directoryPath);
              });
            }
          }
        });
      }
    } else {
      // Apre il dialog di scelta della directory
      String? dirPath = await FilePicker.platform.getDirectoryPath();

      // Salva il path della directory e imposta il nome della colonna in base alla directory scelta
      if (dirPath != null && dirPath.isNotEmpty) {
        setState(() {
          directoryPath = dirPath;
          columnName = path.basename(dirPath);
        });
      }
    }
  }

  /// Gestisce il campo di testo editabile del nome
  Widget editTitleTextField() {
    if (isEditingTitle) {
      return Center(
        child: TextField(
          onChanged: (newValue) {
            columnName = newValue;
          },
          autofocus: true,
          controller: titleEditingController,
        ),
      );
    } else {
      return InkWell(
          onTap: () {
            setState(() {
              isEditingTitle = true;
            });
          },
          child: Text(
            columnName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: Themes.columnSettingsFontSize,
            ),
          ));
    }
  }

  /// Verifica che i permessi necessari in base alla piattaforma siano garantiti
  Future<bool> permissionsGranted() async {
    PermissionStatus storageStatus = await Permission.storage.request();
    PermissionStatus audioStorageStatus = await Permission.audio.request();
    PermissionStatus videosStorageStatus = await Permission.videos.request();
    PermissionStatus externalStorageStatus = await Permission.manageExternalStorage.request();
    PermissionStatus mediaLibraryStatus = await Permission.mediaLibrary.request();

    if (Platform.isIOS) {
      return mediaLibraryStatus.isGranted;
    } else if (Platform.isAndroid) {
      return storageStatus.isGranted && audioStorageStatus.isGranted && videosStorageStatus.isGranted && externalStorageStatus.isGranted;
    }

    return false;
  }
}
