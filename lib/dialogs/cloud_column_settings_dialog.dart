import 'package:bardic_beats/dialogs/github_dialog.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nanoid/nanoid.dart';
import 'package:provider/provider.dart';

import 'package:bardic_beats/files_provider.dart';
import 'package:bardic_beats/enums/column_characteristics_enum.dart';
import 'package:bardic_beats/enums/cloud_type_enum.dart';
import 'package:bardic_beats/utility/column_dialog_functions.dart';
import 'package:bardic_beats/enums/column_type_enum.dart';
import 'package:bardic_beats/enums/operation_enum.dart';
import 'package:bardic_beats/utility/string_extension.dart';
import 'package:bardic_beats/utility/themes.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class CloudColumnSettingsDialog extends StatefulWidget {
  final bool newCol;
  final String? columnId;

  const CloudColumnSettingsDialog({super.key, required this.newCol, this.columnId});

  @override
  State<CloudColumnSettingsDialog> createState() => _CloudColumnSettingsDialogState();
}

class _CloudColumnSettingsDialogState extends State<CloudColumnSettingsDialog> {
  late bool newCol;

  late String colTitle;
  late String columnId;
  late int columnColor;
  late String columnName;
  late int fontColor;
  late bool hasLoop;
  late double columnVolume;
  late bool hasFading;
  late CloudType cloudType;
  late TextEditingController titleEditingController;
  late TextEditingController repositoryOwnerEditingController;
  late TextEditingController repositoryNameEditingController;
  late FilesProvider filesProvider;

  String repositoryOwner = "";
  String repositoryName = "";
  List<String> urlsList = ["url"];
  List<String> urlsValid = [];
  bool isEditingTitle = false;
  bool isEditingRepositoryOwner = false;
  bool isEditingRepositoryName = false;
  List<TargetFocus> targets = [];
  // Evita che un rebuild della colonna scateni nuovamente il tutorial
  bool mustShowTutorial = false;
  Map<String, GlobalKey> keyTargets = {
    "headerKey": GlobalKey(),
    "chooseCloudTypeKey": GlobalKey(),
    "createRepositoryKey": GlobalKey(),
    "ownerKey": GlobalKey(),
    "repositoryKey": GlobalKey(),
    "urlsKey": GlobalKey(),
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

  final ScrollController scrollController = ScrollController();
  final dio = Dio();

  @override
  void initState() {
    super.initState();

    newCol = widget.newCol;

    filesProvider = Provider.of<FilesProvider>(context, listen: false);

    columnId = widget.columnId ?? customAlphabet("1234567890abcdefghijklmnopqrstuvwxy", 10);
    columnVolume = 5.0;
    mustShowTutorial = filesProvider.showCloudTutorial;

    if (newCol) {
      // Se si sta aprendo una colonna nuova pre-popola i campi con i dati standard
      colTitle = translate("popup.new_cloud_column");
      columnName = CloudType.gitHubRepository.value;
      cloudType = CloudType.gitHubRepository;
      repositoryOwner = "IntoDice";
      repositoryName = "BardicBeats";
      columnColor = filesProvider.mainColor;
      fontColor = filesProvider.fontColor;
      hasLoop = true;
      hasFading = true;
    } else {
      // Se si sta aprendo una colonna esistente pre-popola i campi con i dati in memoria
      List<String> columnCharacteristics = filesProvider.columnCharacteristics[columnId]!;
      cloudType = CloudTypeExtension.fromString(columnCharacteristics[ColumnCharacteristic.cloudType.position])!;
      if (cloudType == CloudType.gitHubRepository) {
        repositoryOwner = columnCharacteristics[ColumnCharacteristic.repositoryOwner.position];
        repositoryName = columnCharacteristics[ColumnCharacteristic.repositoryName.position];
      }
      String stringedUrlsList = columnCharacteristics[ColumnCharacteristic.urlsList.position];
      urlsList = stringedUrlsList.substring(1, stringedUrlsList.length - 1).split(", ").toList();
      columnColor = int.parse(columnCharacteristics[ColumnCharacteristic.columnColor.position]);
      columnName = columnCharacteristics[ColumnCharacteristic.columnName.position];
      fontColor = int.parse(columnCharacteristics[ColumnCharacteristic.fontColor.position]);
      hasLoop = columnCharacteristics[ColumnCharacteristic.hasLoop.position].toBoolean();
      hasFading = columnCharacteristics[ColumnCharacteristic.hasFading.position].toBoolean();
      colTitle = translate("popup.edit_cloud_column");
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
          columnType: ColumnType.cloudColumn,
          cloudType: cloudType,
          keyTargets: keyTargets,
          fontColor: fontColor,
          newCol: newCol,
        );

        showTutorial(
          context: context,
          targets: targets,
          keyTargets: keyTargets,
          scrollController: scrollController,
          columnType: ColumnType.cloudColumn,
        );

        filesProvider.setShowCloudTutorial(false);
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
              onPressed: () async {
                targets = createTutorial(
                  columnType: ColumnType.cloudColumn,
                  cloudType: cloudType,
                  keyTargets: keyTargets,
                  fontColor: fontColor,
                  newCol: newCol,
                );

                showTutorial(
                  context: context,
                  targets: targets,
                  keyTargets: keyTargets,
                  scrollController: scrollController,
                  columnType: ColumnType.cloudColumn,
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
            // Gestisce la scelta del tipo di colonna online
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.language),
                  color: Colors.grey,
                  onPressed: () {},
                ),
                DropdownButton<CloudType>(
                  key: keyTargets["chooseCloudTypeKey"],
                  value: cloudType,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: Themes.iconSize,
                  elevation: Themes.dropdownButtonElevation,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: Themes.columnSettingsFontSize,
                  ),
                  underline: Container(
                    height: 2,
                    color: Colors.black,
                  ),
                  onChanged: (CloudType? data) {
                    if (data != null) {
                      setState(() {
                        cloudType = data;
                        columnName = data.value;
                      });
                    }
                  },
                  items: CloudType.values
                      .map((CloudType cloudType) => DropdownMenuItem<CloudType>(
                            value: cloudType,
                            child: Text(
                              cloudType.value,
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
            if (cloudType == CloudType.gitHubRepository)
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
            if (cloudType == CloudType.urls)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.link),
                    color: Colors.grey,
                    onPressed: () {},
                  ),
                  Expanded(
                    key: keyTargets["urlsKey"],
                    child: Column(
                      children: urlsList.mapIndexed((int index, String url) {
                        TextEditingController controller = TextEditingController(text: url);

                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: index == 0 ? translate("popup.urls") : null,
                                ),
                                controller: controller,
                                onChanged: (newValue) {
                                  urlsList[index] = newValue;
                                },
                                style: TextStyle(
                                  color: urlsValid.contains(urlsList[index]) ? Colors.green : Colors.red,
                                  fontSize: Themes.columnSettingsFontSize,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              color: Colors.grey,
                              onPressed: () {
                                setState(() {
                                  urlsList.removeAt(index);
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    color: Color(columnColor),
                    onPressed: () {
                      setState(() {
                        urlsList.add("url");
                      });
                    },
                  ),
                ],
              ),
            ...genericColumnSettings(
              columnType: ColumnType.cloudColumn,
              cloudType: cloudType,
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
                  ColumnCharacteristic.cloudType: cloudType.value,
                  ColumnCharacteristic.repositoryOwner: repositoryOwner,
                  ColumnCharacteristic.repositoryName: repositoryName,
                  ColumnCharacteristic.urlsList: urlsValid.toString(),
                  ColumnCharacteristic.columnType: ColumnType.cloudColumn.value,
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
                    bool columnSavable = true;

                    // In base al tipo di colonna selezionato verifica se ci sono dei file validi
                    // Se un controllo non va a buon fine blocca il salvataggio della colonna
                    if (cloudType == CloudType.gitHubRepository) {
                      urlsValid = await populateFromRepository(dio, repositoryOwner, repositoryName);

                      // Visualizza un toast di avviso se non ci sono file validi nel repository
                      if (urlsValid.isEmpty) {
                        columnSavable = false;
                        Fluttertoast.showToast(
                          msg: translate("popup.no_files", args: {"audio_types": Themes.playableFiles.join(", ")}),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.SNACKBAR,
                          timeInSecForIosWeb: 1,
                          fontSize: Themes.toastFontSize,
                        );
                      }
                    } else if (cloudType == CloudType.urls) {
                      urlsValid = await checkUrlsValidity(dio, urlsList);

                      // Se le due liste non hanno gli stessi elementi alcuni url non sono validi
                      if (urlsValid.length != urlsList.length) {
                        columnSavable = false;
                        Fluttertoast.showToast(
                          msg: translate("popup.urls_not_valid"),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.SNACKBAR,
                          timeInSecForIosWeb: 1,
                          fontSize: Themes.toastFontSize,
                        );
                        setState(() {});
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
                        ColumnCharacteristic.cloudType: cloudType.value,
                        ColumnCharacteristic.repositoryOwner: repositoryOwner,
                        ColumnCharacteristic.repositoryName: repositoryName,
                        ColumnCharacteristic.urlsList: urlsValid.toString(),
                        ColumnCharacteristic.columnType: ColumnType.cloudColumn.value,
                      };
                      await FirebaseAnalytics.instance.logEvent(
                        name: "new_column",
                        parameters: {
                          "column_type": ColumnType.cloudColumn.value,
                          "inner_type": cloudType.value,
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
}
