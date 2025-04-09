import 'dart:convert';
import 'dart:ui';

import 'package:bardic_beats/enums/bard_public_type_enum.dart';
import 'package:bardic_beats/enums/cloud_type_enum.dart';
import 'package:bardic_beats/enums/column_type_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nanoid/nanoid.dart';

import 'package:bardic_beats/files_provider.dart';
import 'package:bardic_beats/managers/shared_preferences_manager.dart';
import 'package:bardic_beats/enums/column_characteristics_enum.dart';
import 'package:bardic_beats/enums/operation_enum.dart';
import 'package:bardic_beats/utility/themes.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Salva la colonna
void saveColumn(bool newCol, String columnId, Map<ColumnCharacteristic, String> characteristicsMap, FilesProvider filesProvider) {
  // Salva l`id in ColumnsId
  if (newCol) {
    SharedPreferencesManager.updateColumnList(columnId);
  }

  List<String> columnCharacteristics = createCharacteristicsList(characteristicsMap);
  // Salva le impostazioni come lista usando l`id come chiave
  SharedPreferencesManager.updateKV(columnId, Operation.update, columnCharacteristics);

  filesProvider.getFilesList(columnId: columnId);
}

/// Crea una lista di caratteristiche nell'ordine corretto per essere salvate
List<String> createCharacteristicsList(Map<ColumnCharacteristic, String> characteristicsMap) {
  List<String> characteristicsList = List.filled(ColumnCharacteristic.values.length, "");
  for (ColumnCharacteristic key in characteristicsMap.keys) {
    characteristicsList[key.position] = characteristicsMap[key]!;
  }

  return characteristicsList;
}

/// Aggiorna le musiche nella colonna
void updateCol(String columnId, FilesProvider filesProvider) {
  filesProvider.getFilesList(columnId: columnId);
}

/// Duplica la colonna
void duplicateCol(Map<ColumnCharacteristic, String> characteristicsMap, FilesProvider filesProvider) {
  // Imposta la variabile a true in modo da scatenare la creazione di una nuova colonna
  bool newCol = true;
  // Crea un nuovo id della colonna
  String columnId = customAlphabet("1234567890abcdefghijklmnopqrstuvwxy", 10);

  // Salva la nuova colonna senza modificarne gli attributi
  saveColumn(newCol, columnId, characteristicsMap, filesProvider);
}

/// Elimina una colonna salvata
void deleteCol(String columnId, FilesProvider filesProvider, [String? sessionId]) {
  // Cancella l`id da ColumnsId
  SharedPreferencesManager.updateColumnList(columnId);

  // Cancella la lista usando l`id come chiave
  SharedPreferencesManager.updateKV(columnId, Operation.delete);

  // Se è stato passato un sessionId cancella il documento da firebase
  if (sessionId != null) {
    FirebaseFirestore db = FirebaseFirestore.instance;
    db.collection("sessions").doc(sessionId).delete();
  }

  filesProvider.deleteColumn(columnId: columnId);
}

/// Verifica se il repository è valido e contiene file audio adatti
Future<List<String>> populateFromRepository(Dio dio, String owner, String name) async {
  List<String> urlsList = [];

  // Controlla se il repository esiste
  try {
    final Response<dynamic> response = await dio.get("https://api.github.com/repos/$owner/$name/contents");

    if (response.statusCode == 200) {
      // Conta i file validi nel repository e popola la lista
      final List<dynamic> content = response.data as List<dynamic>;
      for (dynamic file in content) {
        Map<String, dynamic> mappedFile = file as Map<String, dynamic>;
        String name = mappedFile["name"].toString();
        if (name.contains(".") && Themes.playableFiles.contains(name.substring(name.lastIndexOf(".")))) {
          urlsList.add(mappedFile["download_url"].toString());
        }
      }
    }
  } on DioException {
    // Se l'url non è valido visualizza un avviso
    Fluttertoast.showToast(
      msg: translate("popup.url_not_valid"),
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
      timeInSecForIosWeb: 1,
      fontSize: Themes.toastFontSize,
    );
  }

  return urlsList;
}

/// Restituisce solo gli url validi
Future<List<String>> checkUrlsValidity(Dio dio, List<String> urlsList) async {
  List<String> validUrls = [];
  try {
    for (String url in urlsList) {
      if (url.contains(".") && Themes.playableFiles.contains(url.substring(url.lastIndexOf(".")))) {
        final Response<dynamic> response = await dio.get(url);

        if (response.statusCode == 200) {
          validUrls.add(url);
        }
      }
    }
  } on DioException {
    // Se ci sono degli errori negli url non fa nulla, il controllo avviene dopo
  }

  return validUrls;
}

/// Verifica se l'id inserito è valido
Future<Map<String, dynamic>?> checkSessionIdValidity(String sessionId) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  // Verifica se la sessione esiste
  final docRef = db.collection("sessions").doc(sessionId);
  DocumentSnapshot doc = await docRef.get();

  if (doc.exists) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return data;
  } else {
    return null;
  }
}

/// Crea e restituisce un id valido
Future<String> generateSessionId() async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  String sessionId;
  do {
    sessionId = customAlphabet("1234567890abcdefghijklmnopqrstuvwxy", 5);
  } while ((await db.collection("sessions").doc(sessionId).get()).exists);

  return sessionId;
}

/// Gestisce la scelta del colore
Future<bool> colorPickerDialog(BuildContext context, int startColor, bool opacity, Function callback) async {
  return ColorPicker(
    color: Color(startColor),
    onColorChanged: (Color color) => callback(color),
    width: 40,
    height: 40,
    borderRadius: 0,
    spacing: 0,
    runSpacing: 0,
    columnSpacing: 20,
    showColorName: true,
    enableShadesSelection: true,
    enableTonalPalette: true,
    enableOpacity: opacity,
    materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
    colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
    colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
    pickersEnabled: const <ColorPickerType, bool>{
      ColorPickerType.both: true,
      ColorPickerType.primary: false,
      ColorPickerType.accent: false,
      ColorPickerType.bw: false,
      ColorPickerType.custom: false,
      ColorPickerType.wheel: false,
    },
  ).showPickerDialog(
    context,
    transitionBuilder: (BuildContext context, Animation<double> a1, Animation<double> a2, Widget widget) {
      final double curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
      return Transform(
        transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
        child: Opacity(
          opacity: a1.value,
          child: widget,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
    constraints: const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
  );
}

/// Crea il tutorial in base alla colonna corrente
List<TargetFocus> createTutorial({
  required ColumnType columnType,
  CloudType? cloudType,
  BardPublicType? bardPublicType,
  required Map<String, GlobalKey> keyTargets,
  required int fontColor,
  required bool newCol,
}) {
  List<TargetFocus> targets = [];

  switch (columnType) {
    case ColumnType.directoryColumn:
      targets.add(
        TargetFocus(
          identify: "DirectoryType",
          keyTarget: keyTargets["chooseDirectoryKey"],
          enableOverlayTab: true,
          enableTargetTab: true,
          shape: ShapeLightFocus.RRect,
          radius: 5.0,
          contents: [
            TargetContent(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: Themes.tutorialTitleTopPadding),
                    child: Text(
                      translate("tutorial.directory_column_title"),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: Themes.tutorialTitleFontSize),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                    child: Text(
                      translate("tutorial.choose_directory"),
                      style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      break;

    case ColumnType.defaultColumn:
      targets.add(
        TargetFocus(
          identify: "DefaultType",
          keyTarget: keyTargets["chooseDefaultTypeKey"],
          enableOverlayTab: true,
          enableTargetTab: true,
          shape: ShapeLightFocus.RRect,
          radius: 5.0,
          contents: [
            TargetContent(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: Themes.tutorialTitleTopPadding),
                    child: Text(
                      translate("tutorial.default_column_title"),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: Themes.tutorialTitleFontSize),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                    child: Text(
                      translate("tutorial.choose_default"),
                      style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      break;

    case ColumnType.cloudColumn:
      targets.add(
        TargetFocus(
          identify: "CloudType",
          keyTarget: keyTargets["chooseCloudTypeKey"],
          enableOverlayTab: true,
          enableTargetTab: true,
          shape: ShapeLightFocus.RRect,
          radius: 5.0,
          contents: [
            TargetContent(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: Themes.tutorialTitleTopPadding),
                    child: Text(
                      translate("tutorial.cloud_column_title"),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: Themes.tutorialTitleFontSize),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                    child: Text(
                      translate("tutorial.choose_cloud"),
                      style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      switch (cloudType) {
        case CloudType.gitHubRepository:
          targets.addAll(
            [
              TargetFocus(
                identify: "CreateRepository",
                keyTarget: keyTargets["createRepositoryKey"],
                enableOverlayTab: true,
                enableTargetTab: true,
                shape: ShapeLightFocus.RRect,
                radius: 5.0,
                contents: [
                  TargetContent(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: Themes.tutorialTitleTopPadding),
                          child: Text(
                            translate("tutorial.github_repository_title"),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: Themes.tutorialTitleFontSize),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                          child: Text(
                            translate("tutorial.create_repository"),
                            style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TargetFocus(
                identify: "Owner",
                keyTarget: keyTargets["ownerKey"],
                enableOverlayTab: true,
                enableTargetTab: true,
                shape: ShapeLightFocus.RRect,
                radius: 5.0,
                contents: [
                  TargetContent(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                          child: Text(
                            translate("tutorial.github_owner"),
                            style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TargetFocus(
                identify: "Repository",
                keyTarget: keyTargets["repositoryKey"],
                enableOverlayTab: true,
                enableTargetTab: true,
                shape: ShapeLightFocus.RRect,
                radius: 5.0,
                contents: [
                  TargetContent(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                          child: Text(
                            translate("tutorial.github_repository"),
                            style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
          break;

        case CloudType.urls:
          targets.add(
            TargetFocus(
              identify: "Urls",
              keyTarget: keyTargets["urlsKey"],
              enableOverlayTab: true,
              enableTargetTab: true,
              shape: ShapeLightFocus.RRect,
              radius: 5.0,
              contents: [
                TargetContent(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: Themes.tutorialTitleTopPadding),
                        child: Text(
                          translate("tutorial.urls_title"),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: Themes.tutorialTitleFontSize),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                        child: Text(
                          translate("tutorial.urls_list"),
                          style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          break;

        default:
          break;
      }
      break;

    case ColumnType.bardPublicColumn:
      targets.add(
        TargetFocus(
          identify: "BardPublicType",
          keyTarget: keyTargets["chooseBardPublicTypeKey"],
          enableOverlayTab: true,
          enableTargetTab: true,
          shape: ShapeLightFocus.RRect,
          radius: 5.0,
          contents: [
            TargetContent(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: Themes.tutorialTitleTopPadding),
                    child: Text(
                      translate("tutorial.bard_public_column_title"),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: Themes.tutorialTitleFontSize),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                    child: Text(
                      translate("tutorial.choose_bard_public"),
                      style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      if (bardPublicType == BardPublicType.bard) {
        targets.addAll(
          [
            TargetFocus(
              identify: "CreateRepository",
              keyTarget: keyTargets["createRepositoryKey"],
              enableOverlayTab: true,
              enableTargetTab: true,
              shape: ShapeLightFocus.RRect,
              radius: 5.0,
              contents: [
                TargetContent(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: Themes.tutorialTitleTopPadding),
                        child: Text(
                          translate("tutorial.bard_title"),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: Themes.tutorialTitleFontSize),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                        child: Text(
                          translate("tutorial.create_repository"),
                          style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            TargetFocus(
              identify: "Owner",
              keyTarget: keyTargets["ownerKey"],
              enableOverlayTab: true,
              enableTargetTab: true,
              shape: ShapeLightFocus.RRect,
              radius: 5.0,
              contents: [
                TargetContent(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                        child: Text(
                          translate("tutorial.github_owner"),
                          style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            TargetFocus(
              identify: "Repository",
              keyTarget: keyTargets["repositoryKey"],
              enableOverlayTab: true,
              enableTargetTab: true,
              shape: ShapeLightFocus.RRect,
              radius: 5.0,
              contents: [
                TargetContent(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                        child: Text(
                          translate("tutorial.github_repository"),
                          style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            TargetFocus(
              identify: "SessionId",
              keyTarget: keyTargets["sessionIdKey"],
              enableOverlayTab: true,
              enableTargetTab: true,
              shape: ShapeLightFocus.RRect,
              radius: 5.0,
              contents: [
                TargetContent(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                        child: Text(
                          translate("tutorial.bard_session_id"),
                          style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      } else {
        targets.add(
          TargetFocus(
            identify: "SessionId",
            keyTarget: keyTargets["sessionIdKey"],
            enableOverlayTab: true,
            enableTargetTab: true,
            shape: ShapeLightFocus.RRect,
            radius: 5.0,
            contents: [
              TargetContent(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: Themes.tutorialTitleTopPadding),
                      child: Text(
                        translate("tutorial.public_title"),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: Themes.tutorialTitleFontSize),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                      child: Text(
                        translate("tutorial.public_session_id"),
                        style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      break;
  }

  targets.addAll(
    [
      TargetFocus(
        identify: "Color",
        keyTarget: keyTargets["colorKey"],
        enableOverlayTab: true,
        enableTargetTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                  child: Text(
                    translate("tutorial.column_color"),
                    style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "FontColor",
        keyTarget: keyTargets["fontKey"],
        enableOverlayTab: true,
        enableTargetTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 5.0,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                  child: Text(
                    translate("tutorial.font_color"),
                    style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Name",
        keyTarget: keyTargets["nameKey"],
        enableOverlayTab: true,
        enableTargetTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 5.0,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                  child: Text(
                    translate("tutorial.column_name"),
                    style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Loop",
        keyTarget: keyTargets["loopKey"],
        enableOverlayTab: true,
        enableTargetTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                  child: Text(
                    translate("tutorial.loop_music"),
                    style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Fade",
        keyTarget: keyTargets["fadeKey"],
        enableOverlayTab: true,
        enableTargetTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                  child: Text(
                    translate("tutorial.fade_music"),
                    style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  if (!newCol) {
    targets.add(
      TargetFocus(
        identify: "Duplicate",
        keyTarget: keyTargets["duplicateKey"],
        enableOverlayTab: true,
        enableTargetTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 5.0,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                  child: Text(
                    translate("tutorial.duplicate_button"),
                    style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  if (!newCol && (columnType == ColumnType.directoryColumn || (cloudType != null && cloudType == CloudType.gitHubRepository) || (columnType == ColumnType.bardPublicColumn))) {
    targets.add(
      TargetFocus(
        identify: "Update",
        keyTarget: keyTargets["updateKey"],
        enableOverlayTab: true,
        enableTargetTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 5.0,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                  child: Text(
                    translate("tutorial.update_button"),
                    style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  if (!newCol) {
    targets.add(
      TargetFocus(
        identify: "Delete",
        keyTarget: keyTargets["deleteKey"],
        enableOverlayTab: true,
        enableTargetTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 5.0,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: Themes.tutorialTextTopPadding),
                  child: Text(
                    translate("tutorial.delete_button"),
                    style: const TextStyle(color: Colors.white, fontSize: Themes.tutorialTextFontSize),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  return targets;
}

/// Mostra il tutorial
Future<void> showTutorial({
  required BuildContext context,
  required List<TargetFocus> targets,
  required Map<String, GlobalKey> keyTargets,
  required ScrollController scrollController,
  required ColumnType columnType,
}) async {
  FilesProvider filesProvider = Provider.of<FilesProvider>(context, listen: false);

  // Verifica che la colonna sia all'inizio e nel caso non lo fosse ce la porta
  GlobalKey keyTarget;
  switch (columnType) {
    case ColumnType.directoryColumn:
      keyTarget = keyTargets["chooseDirectoryKey"]!;
      break;
    case ColumnType.defaultColumn:
      keyTarget = keyTargets["chooseDefaultTypeKey"]!;
      break;
    case ColumnType.cloudColumn:
      keyTarget = keyTargets["chooseCloudTypeKey"]!;
      break;
    case ColumnType.bardPublicColumn:
      keyTarget = keyTargets["chooseBardPublicTypeKey"]!;
      break;
  }
  showTarget(keyTargets: keyTargets, keyTarget: keyTarget, scrollController: scrollController);
  await Future<void>.delayed(const Duration(milliseconds: Themes.rapidDelayAfterScroll));

  if (context.mounted) {
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      unFocusAnimationDuration: const Duration(milliseconds: 400),
      pulseAnimationDuration: const Duration(milliseconds: 500),
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      textSkip: translate("tutorial.skip_button"),
      textStyleSkip: const TextStyle(color: Colors.white),
      hideSkip: false,
      paddingFocus: 5,
      opacityShadow: 0.6,
      onSkip: () {
        switch (columnType) {
          case ColumnType.directoryColumn:
            filesProvider.setShowDirectoryTutorial(false);
            break;
          case ColumnType.defaultColumn:
            filesProvider.setShowDefaultTutorial(false);
            break;
          case ColumnType.cloudColumn:
            filesProvider.setShowCloudTutorial(false);
            break;
          case ColumnType.bardPublicColumn:
            filesProvider.setShowBardPublicTutorial(false);
            break;
        }
        return true;
      },
      onFinish: () {
        switch (columnType) {
          case ColumnType.directoryColumn:
            filesProvider.setShowDirectoryTutorial(false);
            break;
          case ColumnType.defaultColumn:
            filesProvider.setShowDefaultTutorial(false);
            break;
          case ColumnType.cloudColumn:
            filesProvider.setShowCloudTutorial(false);
            break;
          case ColumnType.bardPublicColumn:
            filesProvider.setShowBardPublicTutorial(false);
            break;
        }
      },
      onClickOverlay: (TargetFocus target) async {
        int current = targets.indexOf(target);

        if (current + 1 < targets.length) {
          showTarget(keyTargets: keyTargets, keyTarget: targets.elementAt(current + 1).keyTarget!, scrollController: scrollController);
        }
      },
      onClickTarget: (TargetFocus target) async {
        int current = targets.indexOf(target);

        if (current + 1 < targets.length) {
          showTarget(keyTargets: keyTargets, keyTarget: targets.elementAt(current + 1).keyTarget!, scrollController: scrollController);
        }
      },
    ).show(context: context);
  }
}

/// Verifica che l'elemento desiderato sia visibile e sposta la colonna di conseguenza
void showTarget({
  required Map<String, GlobalKey> keyTargets,
  required GlobalKey keyTarget,
  required ScrollController scrollController,
}) {
  // La coordinata alta e quella bassa dell'elemento
  final RenderBox targetObj = keyTarget.currentContext!.findRenderObject() as RenderBox;
  final double targetObjTopCoord = targetObj.localToGlobal(Offset.zero).dy;
  final double targetObjHeight = targetObj.size.height;
  final double targetObjBottomCoord = targetObjTopCoord + targetObjHeight;

  // La coordinata bassa dell'header
  final RenderBox header = keyTargets["headerKey"]!.currentContext!.findRenderObject() as RenderBox;
  final double headerY = header.localToGlobal(Offset.zero).dy;
  final double headerHeight = header.size.height;
  final double headerBottomCoord = headerY + headerHeight;

  // La coordinata alta del pulsante salva
  final RenderBox save = keyTargets["saveKey"]!.currentContext!.findRenderObject() as RenderBox;
  final double saveTopCoord = save.localToGlobal(Offset.zero).dy;

  // Se l'elemento è più in alto dell'header sposta la colonna in cima
  if (headerBottomCoord > targetObjTopCoord) {
    scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: Themes.rapidColumnScroll),
      curve: Curves.decelerate,
    );

    // await Future<void>.delayed(const Duration(milliseconds: Themes.rapidDelayAfterScroll));
  }
  // Se l'elemento è più in basso del save sposta la colonna in basso
  if (saveTopCoord < targetObjBottomCoord) {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: Themes.rapidColumnScroll),
      curve: Curves.decelerate,
    );

    // await Future<void>.delayed(const Duration(milliseconds: Themes.rapidDelayAfterScroll));
  }
}

/// Creates the generic settings for the columns
List<Widget> genericColumnSettings({
  required ColumnType columnType,
  CloudType? cloudType,
  required Map<String, GlobalKey> keyTargets,
  required int columnColor,
  required BuildContext context,
  required void Function(int) choosedColorCallback,
  required TextEditingController titleEditingController,
  required void Function(String) choosedColorName,
  required int fontColor,
  required void Function(int) choosedFontColorCallback,
  required bool hasLoop,
  required void Function(bool) choosedLoopCallback,
  required bool hasFading,
  required void Function(bool) choosedFadeCallback,
  required bool newCol,
  required void Function() duplicateCallback,
  void Function()? updateCallback,
  required void Function() deleteCallback,
}) {
  return [
    // Gestisce la scelta del colore principale della colonna
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.color_lens_rounded),
          color: Colors.grey,
          onPressed: () {},
        ),
        ColorIndicator(
          key: keyTargets["colorKey"],
          width: 35,
          height: 35,
          borderRadius: 4,
          color: Color(columnColor),
          onSelectFocus: false,
          onSelect: () async {
            final int colorBeforeDialog = columnColor;
            // Se la scelta non viene confermata ripristina il colore precedente
            if (!(await colorPickerDialog(context, columnColor, true, (Color color) {
              choosedColorCallback(color.value);
            }))) {
              choosedColorCallback(colorBeforeDialog);
            }
          },
        ),
      ],
    ),

    // Gestisce il colore del font della colonna
    Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.format_color_text),
          color: Colors.grey,
          onPressed: () {},
        ),
        DropdownButton<int>(
          key: keyTargets["fontKey"],
          value: fontColor,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: Themes.iconSize,
          elevation: Themes.dropdownButtonElevation,
          style: const TextStyle(color: Colors.black, fontSize: Themes.columnSettingsFontSize),
          underline: Container(
            height: 2,
            color: Colors.black,
          ),
          onChanged: (int? data) {
            if (data != null) {
              choosedFontColorCallback(data);
            }
          },
          items: [
            DropdownMenuItem<int>(
              value: Themes.blackValue,
              child: Text(
                translate("colors.black"),
              ),
            ),
            DropdownMenuItem<int>(
              value: Themes.whiteValue,
              child: Text(
                translate("colors.white"),
              ),
            ),
          ],
        ),
      ],
    ),

    // Gestisce il nome della colonna
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.drive_file_rename_outline),
          color: Colors.grey,
          onPressed: () {},
        ),
        Flexible(
          key: keyTargets["nameKey"],
          flex: 2,
          child: Center(
            child: TextField(
              decoration: InputDecoration(
                labelText: translate("popup.column_name"),
              ),
              onChanged: (newValue) {
                choosedColorName(newValue);
              },
              autofocus: false,
              controller: titleEditingController,
            ),
          ),
        ),
      ],
    ),

    // Specifica se le musiche della colonna devono essere riprodotte in loop o meno
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.loop_rounded),
          color: Colors.grey,
          onPressed: () {},
        ),
        Switch(
          key: keyTargets["loopKey"],
          value: hasLoop,
          onChanged: (bool value) {
            choosedLoopCallback(value);
          },
          activeColor: Color(columnColor),
        ),
        hasLoop ? Text(translate("popup.loop")) : Text(translate("popup.not_loop")),
      ],
    ),

    // Specifica se le musiche della colonna devono avere il fading o meno
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.deblur_rounded),
          color: Colors.grey,
          onPressed: () {},
        ),
        Switch(
          key: keyTargets["fadeKey"],
          value: hasFading,
          onChanged: (bool value) {
            choosedFadeCallback(value);
          },
          activeColor: Color(columnColor),
        ),
        hasFading ? Text(translate("popup.fading")) : Text(translate("popup.not_fading")),
      ],
    ),

    // Nel caso in cui si stia guardando le caratteristiche di una colonna esistente mostra pulsanti ulteriori
    if (!newCol)
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Spacer(),
          ElevatedButton(
            key: keyTargets["duplicateKey"],
            style: ElevatedButton.styleFrom(
              elevation: Themes.buttonElevation,
              backgroundColor: Color(columnColor),
              foregroundColor: Color(fontColor),
              padding: const EdgeInsets.all(Themes.padding),
            ),
            onPressed: () {
              duplicateCallback();
            },
            child: const Icon(Icons.content_copy_rounded),
          ),
          if (columnType == ColumnType.directoryColumn || (cloudType != null && cloudType == CloudType.gitHubRepository) || (columnType == ColumnType.bardPublicColumn))
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
          if (columnType == ColumnType.directoryColumn || (cloudType != null && cloudType == CloudType.gitHubRepository) || (columnType == ColumnType.bardPublicColumn))
            ElevatedButton(
              key: keyTargets["updateKey"],
              style: ElevatedButton.styleFrom(
                elevation: Themes.buttonElevation,
                backgroundColor: Color(columnColor),
                foregroundColor: Color(fontColor),
                padding: const EdgeInsets.all(Themes.padding),
              ),
              onPressed: () {
                updateCallback!();
              },
              child: const Icon(Icons.refresh_rounded),
            ),
          const SizedBox(
            height: Themes.spacerHeight,
            width: Themes.spacerWidth,
          ),
          ElevatedButton(
            key: keyTargets["deleteKey"],
            style: ElevatedButton.styleFrom(
              elevation: Themes.buttonElevation,
              backgroundColor: Color(columnColor),
              foregroundColor: Color(fontColor),
              padding: const EdgeInsets.all(Themes.padding),
            ),
            onPressed: () {
              deleteCallback();
            },
            child: const Icon(Icons.delete_rounded),
          ),
        ],
      ),
  ];
}

/// Restituisce la lista di immagini Github a partire da quella specificata
Future<MultiImageProvider> githubImages(int startingIndex) async {
  // Recupera la lista di path delle immagini github
  String manifestContent = await rootBundle.loadString('AssetManifest.json');
  Map<String, dynamic> manifestMap = json.decode(manifestContent) as Map<String, dynamic>;
  List<String> manifestGithubImages = manifestMap.keys.where((String key) => key.contains(Themes.githubAssets)).toList();

  // Separa la lista in base a quella specificata e la ricrea nell'ordine corretto
  List<String> imagesBefore = manifestGithubImages.sublist(0, startingIndex);
  List<String> imagesAfter = manifestGithubImages.sublist(startingIndex, manifestGithubImages.length);
  List<AssetImage> githubImages = (imagesAfter + imagesBefore).map((String assetName) => AssetImage(assetName)).toList();

  return MultiImageProvider(githubImages);
}
