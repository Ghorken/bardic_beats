import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bardic_beats/playify/playify.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firecloud;
import 'package:flutter/material.dart';
import 'package:flutter_color_models/flutter_color_models.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:path/path.dart';
import 'package:bardic_beats/dialogs/bard_public_column_settings_dialog.dart';
import 'package:bardic_beats/dialogs/cloud_column_settings_dialog.dart';
import 'package:bardic_beats/dialogs/default_column_settings_dialog.dart';
import 'package:bardic_beats/dialogs/directory_column_settings_dialog.dart';
import 'package:bardic_beats/files_provider.dart';
import 'package:bardic_beats/managers/shared_preferences_manager.dart';
import 'package:bardic_beats/enums/bard_public_type_enum.dart';
import 'package:bardic_beats/enums/cloud_type_enum.dart';
import 'package:bardic_beats/enums/column_characteristics_enum.dart';
import 'package:bardic_beats/enums/column_type_enum.dart';
import 'package:bardic_beats/enums/default_type_enum.dart';
import 'package:bardic_beats/enums/operation_enum.dart';
import 'package:bardic_beats/utility/string_extension.dart';
import 'package:bardic_beats/utility/themes.dart';

class MusicColumn extends StatefulWidget {
  final String columnId;
  final FilesProvider provider;
  final double columnWidth;
  final double buttonWidth;
  final firecloud.FirebaseFirestore db;

  const MusicColumn({
    super.key,
    required this.columnId,
    required this.provider,
    required this.columnWidth,
    required this.buttonWidth,
    required this.db,
  });

  @override
  State<MusicColumn> createState() => _MusicColumnState();
}

class _MusicColumnState extends State<MusicColumn> {
  late List<String> columnCharacteristics;
  late ColumnType columnType;
  late Color columnColor;
  late Color fontColor;
  late String columnName;
  late bool hasLoop;
  late bool hasFading;
  late double columnVolume;
  String? lastChanged;
  String? lastChangedState;
  DefaultType? defaultType;
  CloudType? cloudType;
  BardPublicType? bardPublicType;
  String? sessionId;
  late List<dynamic> columnFiles;
  Map<String, AudioPlayer> androidPlayers = {};
  Map<String, Playify> iosPlayers = {};
  Map<String, bool> playersFading = {};

  @override
  void initState() {
    // Nel caso in cui si tratti di una colonna di tipo BardPublic si mette in ascolto di eventuali modifiche del db
    columnCharacteristics = widget.provider.columnCharacteristics[widget.columnId]!;
    columnType = ColumnTypeExtension.fromString(columnCharacteristics[ColumnCharacteristic.columnType.position])!;
    if (columnType == ColumnType.bardPublicColumn) {
      bardPublicType = BardPublicTypeExtension.fromString(columnCharacteristics[ColumnCharacteristic.bardPublicType.position]);
      sessionId = columnCharacteristics[ColumnCharacteristic.sessionId.position];

      if (bardPublicType == BardPublicType.public) {
        firecloud.DocumentReference<Map<String, dynamic>> docRef = widget.db.collection("sessions").doc(sessionId);
        docRef.snapshots().listen(
          (event) {
            if (event.data() != null) {
              String changed = event.data()!["changed"] as String;
              String changedState = event.data()!["changedState"] as String;
              if ((changed != lastChanged) || (changed == lastChanged && changedState != lastChangedState)) {
                lastChanged = changed;
                lastChangedState = changedState;
                playPause(
                  lastChanged!,
                  widget.columnId,
                  lastChanged!,
                  columnType,
                  hasLoop,
                  hasFading,
                  columnVolume,
                  sessionId,
                  widget.db,
                  bardPublicType,
                );
              }
            }
          },
        );
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Inizializza tutte le variabili della colonna
    columnCharacteristics = widget.provider.columnCharacteristics[widget.columnId]!;
    columnType = ColumnTypeExtension.fromString(columnCharacteristics[ColumnCharacteristic.columnType.position])!;
    columnColor = Color(int.parse(columnCharacteristics[ColumnCharacteristic.columnColor.position]));
    fontColor = Color(int.parse(columnCharacteristics[ColumnCharacteristic.fontColor.position]));
    columnName = columnCharacteristics[ColumnCharacteristic.columnName.position];
    hasLoop = columnCharacteristics[ColumnCharacteristic.hasLoop.position].toBoolean();
    hasFading = columnCharacteristics[ColumnCharacteristic.hasFading.position].toBoolean();
    columnVolume = double.parse(columnCharacteristics[ColumnCharacteristic.columnVolume.position]);

    if (columnType == ColumnType.defaultColumn) {
      defaultType = DefaultTypeExtension.fromString(columnCharacteristics[ColumnCharacteristic.defaultType.position])!;
    }
    if (columnType == ColumnType.cloudColumn) {
      cloudType = CloudTypeExtension.fromString(columnCharacteristics[ColumnCharacteristic.cloudType.position]);
    }
    columnFiles = widget.provider.files[widget.columnId]!;

    return SizedBox(
      width: widget.columnWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(
            height: Themes.spacerHeight,
            width: Themes.spacerWidth,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Themes.borderRadius),
              color: columnColor,
              image: const DecorationImage(
                image: AssetImage(Themes.singleBorderAsset),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Themes.padding),
              child: Column(
                children: [
                  // Specifica il titolo della colonna e il pulsante di impostazioni
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(Themes.headerSmallPadding),
                          child: Text(
                            columnName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: Themes.headerFontSize,
                              color: fontColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings_rounded,
                          color: fontColor,
                          semanticLabel: translate("settings_page.settings"),
                        ),
                        onPressed: () {
                          showDialog<Operation?>(
                            context: context,
                            builder: (BuildContext context) {
                              switch (columnType) {
                                case ColumnType.directoryColumn:
                                  return DirectoryColumnSettingsDialog(
                                    newCol: false,
                                    columnId: widget.columnId,
                                  );
                                case ColumnType.defaultColumn:
                                  return DefaultColumnSettingsDialog(
                                    newCol: false,
                                    columnId: widget.columnId,
                                  );
                                case ColumnType.cloudColumn:
                                  return CloudColumnSettingsDialog(
                                    newCol: false,
                                    columnId: widget.columnId,
                                  );
                                case ColumnType.bardPublicColumn:
                                  return BardPublicColumnSettingsDialog(
                                    newCol: false,
                                    columnId: widget.columnId,
                                  );
                              }
                            },
                          ).then((Operation? operation) {
                            if (operation == Operation.delete) {
                              deletePlayers();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  // Specifica lo slider del volume della colonna
                  Row(
                    children: [
                      Slider(
                        activeColor: columnColor.toRgbColor().inverted,
                        inactiveColor: fontColor,
                        thumbColor: fontColor,
                        value: columnVolume,
                        max: 10.0,
                        divisions: 10,
                        onChanged: (double value) => updateColumnVolumes(widget.columnId, value),
                        onChangeEnd: (value) {
                          columnCharacteristics[ColumnCharacteristic.columnVolume.position] = value.toString();
                          SharedPreferencesManager.updateKV(widget.columnId, Operation.update, columnCharacteristics);
                        },
                      ),
                      Text(
                        columnVolume.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: Themes.columnFontSize, color: fontColor),
                      )
                    ],
                  ),
                  // Specifica tipo e sottotipo della colonna e impostazioni attivate
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Row(
                          children: [
                            Icon(
                              Themes.icons[columnType.value],
                              color: fontColor,
                            ),
                            const SizedBox(
                              height: Themes.spacerHeight,
                              width: Themes.spacerWidth,
                            ),
                            Expanded(
                              child: AutoSizeText(
                                (defaultType != null)
                                    ? defaultType!.value
                                    : (cloudType != null)
                                        ? cloudType!.value
                                        : (bardPublicType != null)
                                            ? bardPublicType!.value
                                            : "",
                                maxLines: 1,
                                style: TextStyle(
                                  color: fontColor,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxFontSize: Themes.columnFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Row(
                          children: [
                            if (hasLoop)
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: fontColor,
                                ),
                                child: Icon(
                                  Icons.loop_rounded,
                                  color: columnColor,
                                ),
                              ),
                            const SizedBox(
                              height: Themes.spacerHeight,
                              width: Themes.spacerWidth,
                            ),
                            if (hasFading)
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: fontColor,
                                ),
                                child: Icon(
                                  Icons.deblur_rounded,
                                  color: columnColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: Themes.spacerHeight,
            width: Themes.spacerWidth,
          ),
          // Crea la griglia con tutte le musiche di una colonna
          Expanded(
            child: SizedBox(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 2.0,
                ),
                itemCount: columnFiles.length,
                itemBuilder: (context, songIndex) {
                  String? fileName;
                  String? songName;
                  if (columnType == ColumnType.directoryColumn) {
                    fileName = Platform.isIOS ? columnFiles[songIndex].songID.toString() : basenameWithoutExtension((columnFiles[songIndex] as File).path).capitalize();
                    songName = Platform.isIOS ? columnFiles[songIndex].title.toString() : fileName;
                  } else if (columnType == ColumnType.defaultColumn) {
                    fileName = basenameWithoutExtension((columnFiles[songIndex] as File).path).capitalize();
                    songName = translate("default_music.${defaultType!.value.toLowerCase()}.${fileName.toLowerCase()}");
                  } else if (columnType == ColumnType.cloudColumn || columnType == ColumnType.bardPublicColumn) {
                    fileName = columnFiles[songIndex].toString();
                    songName = basenameWithoutExtension(fileName.split("/").last).capitalize().replaceAll("_", " ").replaceAll("-", " ");
                  }

                  return SizedBox(
                    child: GestureDetector(
                      onTap: (bardPublicType != null && bardPublicType == BardPublicType.public)
                          // Se è una colonna bardPublic di tipo pubblico i pulsanti non devono essere premibili
                          ? null
                          : () {
                              playPause(
                                (columnType == ColumnType.cloudColumn || columnType == ColumnType.bardPublicColumn) ? columnFiles[songIndex].toString() : (columnFiles[songIndex] as File).path,
                                widget.columnId,
                                fileName!,
                                columnType,
                                hasLoop,
                                hasFading,
                                columnVolume,
                                sessionId,
                                widget.db,
                                bardPublicType,
                              );
                            },
                      child: Container(
                        margin: const EdgeInsets.all(Themes.buttonMargin),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Themes.borderRadius),
                          color: (androidPlayers["${widget.columnId}-$fileName"] != null && androidPlayers["${widget.columnId}-$fileName"]!.state == PlayerState.playing) ? columnColor.toRgbColor().inverted : columnColor,
                          image: const DecorationImage(
                            image: AssetImage(Themes.doubleBorderAsset),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(Themes.buttonPadding),
                          child: AutoSizeText(
                            songName!,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: Themes.columnFontSize,
                              color: (androidPlayers["${widget.columnId}-$fileName"] != null && androidPlayers["${widget.columnId}-$fileName"]!.state == PlayerState.playing) ? fontColor.toRgbColor().inverted : fontColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(
            height: Themes.spacerHeight,
            width: Themes.spacerWidth,
          ),
        ],
      ),
    );
  }

  /// Mette in play o in pause l`audio selezionato
  void playPause(
    String path,
    String columnId,
    String fileName,
    ColumnType columnType,
    bool hasLoop,
    bool hasFading,
    double columnVolume,
    String? sessionId,
    firecloud.FirebaseFirestore db,
    BardPublicType? bardPublicType,
  ) async {
    // Se il pulsante è di una colonna di tipo bardo/pubblico (bardo) e il sessionId è valorizzato
    // Recupera il db e il documento
    firecloud.DocumentReference<Map<String, dynamic>>? sessionRef;
    if (columnType == ColumnType.bardPublicColumn && sessionId != null) {
      db = firecloud.FirebaseFirestore.instance;
      sessionRef = db.collection("sessions").doc(sessionId);
    }

    if (Platform.isIOS) {
      Playify player = iosPlayers.putIfAbsent("$columnId-$fileName", () => Playify());
      player.playItem(songID: fileName);
    } else if (Platform.isAndroid) {
      // Se il player esiste
      if (androidPlayers.keys.contains("$columnId-$fileName") && androidPlayers["$columnId-$fileName"]!.state != PlayerState.completed) {
        // Se sta riproducendo musica lo mette in pausa altrimenti lo fa ripartire
        AudioPlayer player = androidPlayers["$columnId-$fileName"]!;
        player.onPlayerComplete.listen((event) async {
          setState(() {});
        });
        if (player.state == PlayerState.playing) {
          if (sessionRef != null) {
            sessionRef.update({
              ColumnCharacteristic.changed.name: fileName,
              ColumnCharacteristic.changedState.name: "stop",
            });
          }
          // Se il fading è attivo sfuma prima di disattivare il player
          if (hasFading) {
            if (!playersFading.keys.contains("$columnId-$fileName") || (playersFading.keys.contains("$columnId-$fileName") && !playersFading["$columnId-$fileName"]!)) {
              playersFading["$columnId-$fileName"] = true;
              fade(1.0, 0.0, 3 * 1000, player);
              Timer(const Duration(seconds: 4), () async {
                await player.stop();
                setState(() {
                  playersFading["$columnId-$fileName"] = false;
                });
              });
            }
          } else {
            // Altrimenti lo disattiva subito
            await player.stop();
            setState(() {});
          }
        } else {
          if (sessionRef != null) {
            sessionRef.update({
              ColumnCharacteristic.changed.name: fileName,
              ColumnCharacteristic.changedState.name: "play",
            });
          }
          await player.setReleaseMode(hasLoop ? ReleaseMode.loop : ReleaseMode.release);
          // Se il fading è attivo sfuma dopo aver avviato il player con il volume settato a 0
          if (hasFading) {
            if (!playersFading.keys.contains("$columnId-$fileName") || (playersFading.keys.contains("$columnId-$fileName") && !playersFading["$columnId-$fileName"]!)) {
              playersFading["$columnId-$fileName"] = true;
              player.setVolume(0);
              await player.resume();
              setState(() {});
              fade(0.0, 1.0, 2 * 1000, player);
              playersFading["$columnId-$fileName"] = false;
            }
          } else {
            // Altrimenti lo attiva subito
            await player.resume();
            setState(() {});
          }
        }
      } else {
        // Se il player non esiste
        if (sessionRef != null) {
          sessionRef.update({
            ColumnCharacteristic.changed.name: fileName,
            ColumnCharacteristic.changedState.name: "play",
          });
        }
        AudioPlayer player = androidPlayers.putIfAbsent("$columnId-$fileName", () => AudioPlayer());
        player.onPlayerComplete.listen((event) {
          setState(() {});
        });
        Source source;
        if (columnType == ColumnType.defaultColumn) {
          // Rimuove "assets" dal path
          path = joinAll(split(path)..remove("assets"));
          // Aggiunge la risorsa (a cui viene aggiunto "assets")
          source = AssetSource(path);
        } else if (columnType == ColumnType.directoryColumn) {
          source = DeviceFileSource(path);
        } else {
          source = UrlSource(path);
        }
        await player.setReleaseMode(hasLoop ? ReleaseMode.loop : ReleaseMode.release);
        // Se il fading è attivo sfuma dopo aver avviato il player con volume a 0
        if (hasFading) {
          await player.play(source, volume: 0);
          setState(() {});
          fade(0.0, 1.0, 2 * 1000, player);
        } else {
          // Altrimenti lo avvia con il volume settato
          await player.play(source, volume: columnVolume);
          setState(() {});
        }
      }
    }
  }

  /// Sfuma il volume
  void fade(double from, double to, int len, AudioPlayer player) {
    double vol = from;
    double diff = to - from;
    double steps = (diff / 0.01).abs();
    int stepLen = max(4, (steps > 0) ? len ~/ steps : len);
    int lastTick = DateTime.now().millisecondsSinceEpoch;

    // Aggiorna il volume ad ogni intervallo
    Timer.periodic(Duration(milliseconds: stepLen), (Timer t) {
      var now = DateTime.now().millisecondsSinceEpoch;
      var tick = (now - lastTick) / len;
      lastTick = now;
      vol += diff * tick;

      vol = max(0, vol);
      vol = min(1, vol);
      vol = (vol * 100).round() / 100;

      player.setVolume(vol);

      if ((to < from && vol <= to) || (to > from && vol >= to)) {
        t.cancel();
        player.setVolume(vol);
      }
    });
  }

  /// Aggiorna i volumi della colonna
  void updateColumnVolumes(String columnId, double volume) {
    setState(() {
      // Aggiorna il valore usato dallo slider della colonna
      columnVolume = volume;

      // Aggiorna i volumi di tutti i player della colonna
      androidPlayers.forEach((String key, AudioPlayer player) {
        if (key.split("-")[0] == columnId) {
          player.setVolume(volume / 10);
        }
      });
    });
  }

  /// Elimina i player
  void deletePlayers() {
    androidPlayers.forEach((String playerId, AudioPlayer audioPlayer) {
      // if (!widget.provider.columnCharacteristics.containsKey(playerId.split("-")[0])) {
      audioPlayer.dispose();
      // }
    });
  }
}
