import 'package:bardic_beats/dialogs/github_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nanoid/nanoid.dart';
import 'package:provider/provider.dart';

import 'package:bardic_beats/files_provider.dart';
import 'package:bardic_beats/enums/column_characteristics_enum.dart';
import 'package:bardic_beats/utility/column_dialog_functions.dart';
import 'package:bardic_beats/enums/column_type_enum.dart';
import 'package:bardic_beats/enums/bard_public_type_enum.dart';
import 'package:bardic_beats/enums/operation_enum.dart';
import 'package:bardic_beats/utility/string_extension.dart';
import 'package:bardic_beats/utility/themes.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class BardPublicColumnSettingsDialog extends StatefulWidget {
  final bool newCol;
  final String? columnId;

  const BardPublicColumnSettingsDialog({super.key, required this.newCol, this.columnId});

  @override
  State<BardPublicColumnSettingsDialog> createState() => _BardPublicColumnSettingsDialog();
}

class _BardPublicColumnSettingsDialog extends State<BardPublicColumnSettingsDialog> {
  late bool newCol;

  late String colTitle;
  late String columnId;
  late int columnColor;
  late String columnName;
  late int fontColor;
  late bool hasLoop;
  late double columnVolume;
  late bool hasFading;
  late BardPublicType bardPublicType;
  late String sessionId;
  late TextEditingController titleEditingController;
  late TextEditingController repositoryOwnerEditingController;
  late TextEditingController repositoryNameEditingController;
  late TextEditingController sessionIdEditingController;
  late FilesProvider filesProvider;

  String repositoryOwner = "";
  String repositoryName = "";
  List<String> urlsList = [];
  bool isEditingTitle = false;
  bool isEditingRepositoryOwner = false;
  bool isEditingRepositoryName = false;
  bool isEditingSessionId = false;
  bool isValidSessionId = true;
  List<TargetFocus> targets = [];
  // Evita che un rebuild della colonna scateni nuovamente il tutorial
  bool mustShowTutorial = false;
  Map<String, GlobalKey> keyTargets = {
    "headerKey": GlobalKey(),
    "chooseBardPublicTypeKey": GlobalKey(),
    "createRepositoryKey": GlobalKey(),
    "ownerKey": GlobalKey(),
    "repositoryKey": GlobalKey(),
    "sessionIdKey": GlobalKey(),
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

  final dio = Dio();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    newCol = widget.newCol;

    filesProvider = Provider.of<FilesProvider>(context, listen: false);

    columnId = widget.columnId ?? customAlphabet("1234567890abcdefghijklmnopqrstuvwxy", 10);
    columnVolume = 5.0;
    mustShowTutorial = filesProvider.showBardPublicTutorial;

    if (newCol) {
      // Se si sta aprendo una colonna nuova pre-popola i campi con i dati standard
      colTitle = translate("popup.new_bard_public_column");
      columnName = BardPublicType.bard.value;
      bardPublicType = BardPublicType.bard;
      repositoryOwner = "IntoDice";
      repositoryName = "BardicBeats";
      columnColor = filesProvider.mainColor;
      fontColor = filesProvider.fontColor;
      hasLoop = true;
      hasFading = true;
      sessionId = translate("popup.session_id");
      generateSessionId().then((String id) {
        setState(() {
          sessionId = id;
        });
      });
    } else {
      // Se si sta aprendo una colonna esistente pre-popola i campi con i dati in memoria
      List<String> columnCharacteristics = filesProvider.columnCharacteristics[columnId]!;
      bardPublicType = BardPublicTypeExtension.fromString(columnCharacteristics[ColumnCharacteristic.bardPublicType.position])!;
      repositoryOwner = columnCharacteristics[ColumnCharacteristic.repositoryOwner.position];
      repositoryName = columnCharacteristics[ColumnCharacteristic.repositoryName.position];
      String stringedUrlsList = columnCharacteristics[ColumnCharacteristic.urlsList.position];
      urlsList = stringedUrlsList.substring(1, stringedUrlsList.length - 1).split(", ").toList();
      columnColor = int.parse(columnCharacteristics[ColumnCharacteristic.columnColor.position]);
      columnName = columnCharacteristics[ColumnCharacteristic.columnName.position];
      fontColor = int.parse(columnCharacteristics[ColumnCharacteristic.fontColor.position]);
      hasLoop = columnCharacteristics[ColumnCharacteristic.hasLoop.position].toBoolean();
      hasFading = columnCharacteristics[ColumnCharacteristic.hasFading.position].toBoolean();
      colTitle = translate("popup.edit_bard_public_column");
      sessionId = columnCharacteristics[ColumnCharacteristic.sessionId.position];
    }

    repositoryOwnerEditingController = TextEditingController(text: repositoryOwner);
    repositoryNameEditingController = TextEditingController(text: repositoryName);
  }

  @override
  Widget build(BuildContext context) {
    // La visualizzazione del tutorial viene fatta nel postFrameCallback in modo che la colonna sia già tutta disegnata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mustShowTutorial) {
        targets = createTutorial(
          columnType: ColumnType.bardPublicColumn,
          bardPublicType: bardPublicType,
          keyTargets: keyTargets,
          fontColor: fontColor,
          newCol: newCol,
        );

        showTutorial(
          context: context,
          targets: targets,
          keyTargets: keyTargets,
          scrollController: scrollController,
          columnType: ColumnType.bardPublicColumn,
        );

        filesProvider.setShowBardPublicTutorial(false);
        setState(() {
          mustShowTutorial = false;
        });
      }
    });

    NavigatorState navigator = Navigator.of(context);
    titleEditingController = TextEditingController(text: columnName);
    sessionIdEditingController = TextEditingController(text: sessionId);

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
                  columnType: ColumnType.bardPublicColumn,
                  bardPublicType: bardPublicType,
                  keyTargets: keyTargets,
                  fontColor: fontColor,
                  newCol: newCol,
                );

                showTutorial(
                  context: context,
                  targets: targets,
                  keyTargets: keyTargets,
                  scrollController: scrollController,
                  columnType: ColumnType.bardPublicColumn,
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
            // Gestisce la scelta del tipo di colonna bardo pubblico
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.person),
                  color: Colors.grey,
                  onPressed: () {},
                ),
                DropdownButton<BardPublicType>(
                  key: keyTargets["chooseBardPublicTypeKey"],
                  value: bardPublicType,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: Themes.iconSize,
                  elevation: Themes.dropdownButtonElevation,
                  style: const TextStyle(color: Colors.black, fontSize: Themes.columnSettingsFontSize),
                  underline: Container(
                    height: 2,
                    color: Colors.black,
                  ),
                  onChanged: (BardPublicType? data) {
                    if (data != null) {
                      setState(() {
                        urlsList.clear();
                        bardPublicType = data;
                        columnName = data.value;

                        // Se viene scelto il tipo pubblico svuota il campo sessionId
                        if (data == BardPublicType.public) {
                          sessionId = translate("popup.session_id");
                          isValidSessionId = false;
                        } else {
                          // Se viene scelto il tipo bardo e sto creando una nuova colonna imposta un nuovo sessionId altrimenti recupera quello impostato
                          if (newCol) {
                            sessionId = translate("popup.session_id");
                            generateSessionId().then((String id) {
                              setState(() {
                                sessionId = id;
                              });
                            });
                          } else {
                            List<String> columnCharacteristics = filesProvider.columnCharacteristics[columnId]!;
                            sessionId = columnCharacteristics[ColumnCharacteristic.sessionId.position];
                          }
                        }
                      });
                    }
                  },
                  items: BardPublicType.values
                      .map((BardPublicType bardPublicType) => DropdownMenuItem<BardPublicType>(
                            value: bardPublicType,
                            child: Text(
                              bardPublicType.value,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
            // Gestisce i campi owner e name del repository
            if (bardPublicType == BardPublicType.bard)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.storage),
                    color: Colors.grey,
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            key: keyTargets["createRepositoryKey"],
                            style: ElevatedButton.styleFrom(
                              elevation: Themes.buttonElevation,
                              backgroundColor: Color(columnColor),
                              foregroundColor: Color(fontColor),
                              padding: const EdgeInsets.all(Themes.padding),
                            ),
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (BuildContext context) {
                                  return GithubDialog(
                                    mainColor: columnColor,
                                    fontColor: fontColor,
                                    navigator: navigator,
                                  );
                                },
                              );
                            },
                            child: Text(translate("popup.create_repository")),
                          ),
                        ),
                        Center(
                          child: TextField(
                            key: keyTargets["ownerKey"],
                            decoration: InputDecoration(
                              labelText: translate("popup.git_owner"),
                            ),
                            onChanged: (newOwner) {
                              repositoryOwner = newOwner;
                            },
                            autofocus: false,
                            controller: repositoryOwnerEditingController,
                          ),
                        ),
                        Center(
                          child: TextField(
                            key: keyTargets["repositoryKey"],
                            decoration: InputDecoration(
                              labelText: translate("popup.git_repository"),
                            ),
                            onChanged: (newName) {
                              repositoryName = newName;
                            },
                            autofocus: false,
                            controller: repositoryNameEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            // Gestisce la visualizzazione del campo id della sessione
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.pin),
                  color: Colors.grey,
                  onPressed: () {},
                ),
                Expanded(
                  key: keyTargets["sessionIdKey"],
                  child: Column(
                    children: [
                      Center(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: translate("popup.session_id"),
                          ),
                          onChanged: (newId) {
                            sessionId = newId;
                          },
                          autofocus: false,
                          controller: sessionIdEditingController,
                          // Il campo è editabile solo se si sceglie il tipo pubblico
                          enabled: bardPublicType == BardPublicType.public,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ...genericColumnSettings(
              columnType: ColumnType.bardPublicColumn,
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
                  ColumnCharacteristic.columnColor: columnColor.toString(),
                  ColumnCharacteristic.columnName: columnName,
                  ColumnCharacteristic.fontColor: fontColor.toString(),
                  ColumnCharacteristic.hasLoop: hasLoop.toString(),
                  ColumnCharacteristic.columnVolume: columnVolume.toString(),
                  ColumnCharacteristic.hasFading: hasFading.toString(),
                  ColumnCharacteristic.bardPublicType: bardPublicType.value,
                  ColumnCharacteristic.repositoryOwner: repositoryOwner,
                  ColumnCharacteristic.repositoryName: repositoryName,
                  ColumnCharacteristic.urlsList: urlsList.toString(),
                  ColumnCharacteristic.columnType: ColumnType.bardPublicColumn.value,
                  ColumnCharacteristic.sessionId: sessionId,
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
                if (bardPublicType == BardPublicType.bard) {
                  deleteCol(columnId, filesProvider, sessionId);
                } else if (bardPublicType == BardPublicType.public) {
                  deleteCol(columnId, filesProvider);
                }
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
                    bool columnSavable = true;

                    // In base al tipo di colonna selezionato verifica se ci sono dei file validi
                    // Se un controllo non va a buon fine blocca il salvataggio della colonna
                    if (bardPublicType == BardPublicType.bard) {
                      urlsList = await populateFromRepository(dio, repositoryOwner, repositoryName);

                      // Visualizza un toast di avviso se non ci sono file validi nel repository
                      if (urlsList.isEmpty) {
                        columnSavable = false;
                        Fluttertoast.showToast(
                          msg: translate("popup.no_files", args: {"audio_types": Themes.playableFiles.join(", ")}),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.SNACKBAR,
                          timeInSecForIosWeb: 1,
                          fontSize: Themes.toastFontSize,
                        );
                      } else {
                        FirebaseFirestore db = FirebaseFirestore.instance;
                        // Prepara la mappa da salvare sul db
                        Map<String, dynamic> charsMap = {
                          ColumnCharacteristic.hasLoop.name: hasLoop,
                          ColumnCharacteristic.columnVolume.name: columnVolume,
                          ColumnCharacteristic.hasFading.name: hasFading,
                          ColumnCharacteristic.urlsList.name: urlsList,
                          ColumnCharacteristic.changed.name: "",
                          ColumnCharacteristic.changedState.name: "",
                        };
                        // Crea la sessione
                        db.collection("sessions").doc(sessionId).set(charsMap);
                      }
                    } else if (bardPublicType == BardPublicType.public) {
                      Map<String, dynamic>? data = await checkSessionIdValidity(sessionId);

                      // Se la sessione non esiste avvisa l'utente
                      if (data == null) {
                        columnSavable = false;
                        Fluttertoast.showToast(
                          msg: translate("popup.session_id_not_valid"),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.SNACKBAR,
                          timeInSecForIosWeb: 1,
                          fontSize: Themes.toastFontSize,
                        );
                      } else {
                        isValidSessionId = true;
                        urlsList = List<String>.from(data["urlsList"] as List);
                        columnVolume = data["columnVolume"] as double;
                        hasFading = data["hasFading"] as bool;
                        hasLoop = data["hasLoop"] as bool;
                      }
                    }

                    if (columnSavable) {
                      // Salva la colonna e chiude il popup
                      Map<ColumnCharacteristic, String> characteristicsMap = {
                        ColumnCharacteristic.columnColor: columnColor.toString(),
                        ColumnCharacteristic.columnName: columnName,
                        ColumnCharacteristic.fontColor: fontColor.toString(),
                        ColumnCharacteristic.hasLoop: hasLoop.toString(),
                        ColumnCharacteristic.columnVolume: columnVolume.toString(),
                        ColumnCharacteristic.hasFading: hasFading.toString(),
                        ColumnCharacteristic.bardPublicType: bardPublicType.value,
                        ColumnCharacteristic.repositoryOwner: repositoryOwner,
                        ColumnCharacteristic.repositoryName: repositoryName,
                        ColumnCharacteristic.urlsList: urlsList.toString(),
                        ColumnCharacteristic.columnType: ColumnType.bardPublicColumn.value,
                        ColumnCharacteristic.sessionId: sessionId,
                      };
                      await FirebaseAnalytics.instance.logEvent(
                        name: "new_column",
                        parameters: {
                          "column_type": ColumnType.bardPublicColumn.value,
                          "inner_type": bardPublicType.value,
                        },
                      );
                      saveColumn(newCol, columnId, characteristicsMap, filesProvider);
                      navigator.pop();
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

  /// Gestisce il campo di testo editabile dell'owner del repository
  Widget editRepositoryOwnerTextField() {
    if (isEditingRepositoryOwner) {
      return Center(
        child: TextField(
          onChanged: (newValue) {
            repositoryOwner = newValue;
          },
          autofocus: true,
          controller: repositoryOwnerEditingController,
        ),
      );
    } else {
      return InkWell(
          onTap: () {
            setState(() {
              isEditingRepositoryOwner = true;
            });
          },
          child: Text(
            repositoryOwner,
            style: const TextStyle(
              color: Colors.black,
              fontSize: Themes.columnSettingsFontSize,
            ),
          ));
    }
  }

  /// Gestisce il campo di testo editabile del name del repository
  Widget editRepositoryNameTextField() {
    if (isEditingRepositoryName) {
      return Center(
        child: TextField(
          onChanged: (newValue) {
            repositoryName = newValue;
          },
          autofocus: true,
          controller: repositoryNameEditingController,
        ),
      );
    } else {
      return InkWell(
          onTap: () {
            setState(() {
              isEditingRepositoryName = true;
            });
          },
          child: Text(
            repositoryName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: Themes.columnSettingsFontSize,
            ),
          ));
    }
  }

  /// Gestisce il campo di testo editabile dell'id di sessione
  Widget editSessionIdTextField() {
    if (isEditingSessionId) {
      return Center(
        child: TextField(
          onChanged: (newValue) {
            sessionId = newValue;
          },
          autofocus: true,
          controller: sessionIdEditingController,
        ),
      );
    } else {
      return InkWell(
          onTap: () {
            setState(() {
              isEditingSessionId = true;
            });
          },
          child: Text(
            sessionId,
            style: const TextStyle(
              color: Colors.black,
              fontSize: Themes.columnSettingsFontSize,
            ),
          ));
    }
  }
}
