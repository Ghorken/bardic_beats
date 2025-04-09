import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:nanoid/nanoid.dart';
import 'package:provider/provider.dart';

import 'package:bardic_beats/files_provider.dart';
import 'package:bardic_beats/enums/column_characteristics_enum.dart';
import 'package:bardic_beats/utility/column_dialog_functions.dart';
import 'package:bardic_beats/enums/column_type_enum.dart';
import 'package:bardic_beats/enums/default_type_enum.dart';
import 'package:bardic_beats/enums/operation_enum.dart';
import 'package:bardic_beats/utility/string_extension.dart';
import 'package:bardic_beats/utility/themes.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class DefaultColumnSettingsDialog extends StatefulWidget {
  final bool newCol;
  final String? columnId;

  const DefaultColumnSettingsDialog({super.key, required this.newCol, this.columnId});

  @override
  State<DefaultColumnSettingsDialog> createState() => _DefaultColumnSettingsDialogState();
}

class _DefaultColumnSettingsDialogState extends State<DefaultColumnSettingsDialog> {
  late bool newCol;

  late String colTitle;
  late String columnId;
  late DefaultType defaultType;
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
    "chooseDefaultTypeKey": GlobalKey(),
    "colorKey": GlobalKey(),
    "nameKey": GlobalKey(),
    "fontKey": GlobalKey(),
    "loopKey": GlobalKey(),
    "fadeKey": GlobalKey(),
    "duplicateKey": GlobalKey(),
    "deleteKey": GlobalKey(),
    "saveKey": GlobalKey(),
  };
  bool loading = false;

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    newCol = widget.newCol;

    filesProvider = Provider.of<FilesProvider>(context, listen: false);

    columnId = widget.columnId ?? customAlphabet("1234567890abcdefghijklmnopqrstuvwxy", 10);
    columnVolume = 5.0;
    mustShowTutorial = filesProvider.showDefaultTutorial;

    if (newCol) {
      // Se si sta aprendo una colonna nuova pre-popola i campi con i dati standard
      colTitle = translate("popup.new_default_column");
      columnName = DefaultType.mood.value;
      defaultType = DefaultType.mood;
      columnColor = filesProvider.mainColor;
      fontColor = filesProvider.fontColor;
      hasLoop = true;
      hasFading = true;
    } else {
      // Se si sta aprendo una colonna esistente pre-popola i campi con i dati in memoria
      List<String> columnCharacteristics = filesProvider.columnCharacteristics[columnId]!;
      defaultType = DefaultTypeExtension.fromString(columnCharacteristics[ColumnCharacteristic.defaultType.position])!;
      columnColor = int.parse(columnCharacteristics[ColumnCharacteristic.columnColor.position]);
      columnName = columnCharacteristics[ColumnCharacteristic.columnName.position];
      fontColor = int.parse(columnCharacteristics[ColumnCharacteristic.fontColor.position]);
      hasLoop = columnCharacteristics[ColumnCharacteristic.hasLoop.position].toBoolean();
      hasFading = columnCharacteristics[ColumnCharacteristic.hasFading.position].toBoolean();
      colTitle = translate("popup.edit_default_column");
    }
  }

  @override
  Widget build(BuildContext context) {
    // La visualizzazione del tutorial viene fatta nel postFrameCallback in modo che la colonna sia già tutta disegnata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mustShowTutorial) {
        targets = createTutorial(
          columnType: ColumnType.defaultColumn,
          keyTargets: keyTargets,
          fontColor: fontColor,
          newCol: newCol,
        );

        showTutorial(
          context: context,
          targets: targets,
          keyTargets: keyTargets,
          scrollController: scrollController,
          columnType: ColumnType.defaultColumn,
        );

        filesProvider.setShowDefaultTutorial(false);
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
                  columnType: ColumnType.defaultColumn,
                  keyTargets: keyTargets,
                  fontColor: fontColor,
                  newCol: newCol,
                );

                showTutorial(
                  context: context,
                  targets: targets,
                  keyTargets: keyTargets,
                  scrollController: scrollController,
                  columnType: ColumnType.defaultColumn,
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
            // Gestisce la scelta del tipo di colonna di default
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_rounded),
                  color: Colors.grey,
                  onPressed: () {},
                ),
                DropdownButton<DefaultType>(
                  key: keyTargets["chooseDefaultTypeKey"],
                  value: defaultType,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: Themes.iconSize,
                  elevation: Themes.dropdownButtonElevation,
                  style: const TextStyle(color: Colors.black, fontSize: Themes.columnSettingsFontSize),
                  underline: Container(
                    height: 2,
                    color: Colors.black,
                  ),
                  onChanged: (DefaultType? data) {
                    if (data != null) {
                      setState(() {
                        defaultType = data;
                        columnName = data.value;
                        // Preimposta gli switch in base al tipo di colonna scelto
                        if (defaultType == DefaultType.soundboard) {
                          hasFading = false;
                          hasLoop = false;
                        } else if (defaultType == DefaultType.mood) {
                          hasFading = false;
                          hasLoop = true;
                        } else {
                          hasFading = true;
                          hasLoop = false;
                        }
                      });
                    }
                  },
                  items: DefaultType.values
                      .map((DefaultType defaultType) => DropdownMenuItem<DefaultType>(
                            value: defaultType,
                            child: Text(
                              defaultType.value,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            ...genericColumnSettings(
              columnType: ColumnType.defaultColumn,
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
                  ColumnCharacteristic.defaultType: defaultType.value,
                  ColumnCharacteristic.columnType: ColumnType.defaultColumn.value,
                };
                duplicateCol(characteristicsMap, filesProvider);
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
                    // Salva la colonna e chiude il popup
                    Map<ColumnCharacteristic, String> characteristicsMap = {
                      ColumnCharacteristic.columnColor: columnColor.toString(),
                      ColumnCharacteristic.columnName: columnName,
                      ColumnCharacteristic.fontColor: fontColor.toString(),
                      ColumnCharacteristic.hasLoop: hasLoop.toString(),
                      ColumnCharacteristic.columnVolume: columnVolume.toString(),
                      ColumnCharacteristic.hasFading: hasFading.toString(),
                      ColumnCharacteristic.defaultType: defaultType.value,
                      ColumnCharacteristic.columnType: ColumnType.defaultColumn.value,
                    };
                    await FirebaseAnalytics.instance.logEvent(
                      name: "new_column",
                      parameters: {
                        "column_type": ColumnType.defaultColumn.value,
                        "inner_type": defaultType.value,
                      },
                    );
                    saveColumn(newCol, columnId, characteristicsMap, filesProvider);
                    navigator.pop();
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
}
