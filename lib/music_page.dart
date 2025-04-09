import 'package:cloud_firestore/cloud_firestore.dart' as firecloud;
// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:bardic_beats/dialogs/cloud_column_settings_dialog.dart';
import 'package:bardic_beats/dialogs/default_column_settings_dialog.dart';
import 'package:bardic_beats/dialogs/directory_column_settings_dialog.dart';
import 'package:bardic_beats/dialogs/bard_public_column_settings_dialog.dart';
import 'package:bardic_beats/music_column.dart';
import 'package:bardic_beats/utility/themes.dart';
import 'package:bardic_beats/files_provider.dart';

class MusicPage extends StatefulWidget {
  final ValueNotifier<double> notifier;

  const MusicPage({super.key, required this.notifier});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  // Variabili condivise
  //TODO: Rimuovere le 3 variabili commentate di seguito
  // Map<String, List<Source>> files = {};
  // List<String> states = [];

  final ScrollController horizontalScrollController = ScrollController();
  // final ScrollController verticalScrollController = ScrollController();

  late FilesProvider filesProvider;
  late firecloud.FirebaseFirestore db;

  /// Gestisce lo scroll del background per l'effetto parallasse
  void onScroll(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);

    double scrolledSections = horizontalScrollController.offset / (mediaQuery.size.width / 3);
    double percentageScrolledSections = scrolledSections / (filesProvider.files.length * 3 + 1);

    double originalBackgroundHeight = filesProvider.loadedBackgroundHeight;
    double originalBackgroundWidth = filesProvider.loadedBackgroundWidth;
    if (originalBackgroundHeight != 0 && originalBackgroundWidth != 0) {
      double screenHeight = mediaQuery.size.height - 80 - AppBar().preferredSize.height;
      double newBackgroundWidth = screenHeight / originalBackgroundHeight * originalBackgroundWidth;
      double backgroundToScroll = newBackgroundWidth * percentageScrolledSections;

      if (backgroundToScroll > (newBackgroundWidth - mediaQuery.size.width)) {
        backgroundToScroll = (newBackgroundWidth - mediaQuery.size.width);
      }
      if (backgroundToScroll < 0.0) {
        backgroundToScroll = 0.0;
      }

      widget.notifier.value = backgroundToScroll;
    } else {
      widget.notifier.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    filesProvider = Provider.of<FilesProvider>(context, listen: true);
    db = firecloud.FirebaseFirestore.instance;
    MediaQueryData mediaQuery = MediaQuery.of(context);
    double buttonColumnWidth = mediaQuery.size.width / 3;
    double columnWidth = buttonColumnWidth * 2;
    double buttonWidth = mediaQuery.size.width / 5;

    // Imposta lo stato di veglia dello schermo in base alle impostazioni settate
    WakelockPlus.toggle(enable: filesProvider.screenAlwaysOn);

    return Center(
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Elenco delle colonne
              Expanded(
                child: NotificationListener(
                  onNotification: (t) {
                    setState(() {
                      onScroll(context);
                    });
                    return true;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.only(left: Themes.padding),
                    scrollDirection: Axis.horizontal,
                    controller: horizontalScrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: filesProvider.files.length + 1,
                    itemBuilder: (BuildContext context, int colIndex) {
                      // L`ultima colonna è quella con il pulsante per aggiungere altre colonne
                      if (colIndex == filesProvider.files.length) {
                        return SizedBox(
                          width: buttonColumnWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Aggiunge una colonna directory
                              if (!kIsWeb)
                                GestureDetector(
                                  onTap: () {
                                    showDialog<void>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return const DirectoryColumnSettingsDialog(
                                          newCol: true,
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    width: buttonWidth,
                                    height: Themes.buttonHeight,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Themes.borderRadius),
                                      color: Color(filesProvider.mainColor),
                                      image: const DecorationImage(
                                        image: AssetImage(Themes.doubleBorderAsset),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(Themes.buttonPadding),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.folder_rounded,
                                            color: Color(filesProvider.fontColor),
                                            semanticLabel: translate("popup.new_column"),
                                          ),
                                          Icon(
                                            Icons.add_rounded,
                                            color: Color(filesProvider.fontColor),
                                            semanticLabel: translate("popup.new_column"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(
                                height: Themes.spacerHeight,
                                width: Themes.spacerWidth,
                              ),
                              // Aggiunge una colonna di default
                              GestureDetector(
                                onTap: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return const DefaultColumnSettingsDialog(
                                        newCol: true,
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  width: buttonWidth,
                                  height: Themes.buttonHeight,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Themes.borderRadius),
                                    color: Color(filesProvider.mainColor),
                                    image: const DecorationImage(
                                      image: AssetImage(Themes.doubleBorderAsset),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(Themes.buttonPadding),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.system_update_rounded,
                                          color: Color(filesProvider.fontColor),
                                          semanticLabel: translate("popup.new_column"),
                                        ),
                                        Icon(
                                          Icons.add_rounded,
                                          color: Color(filesProvider.fontColor),
                                          semanticLabel: translate("popup.new_column"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: Themes.spacerHeight,
                                width: Themes.spacerWidth,
                              ),
                              // Aggiunge una colonna di url
                              GestureDetector(
                                onTap: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return const CloudColumnSettingsDialog(
                                        newCol: true,
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  width: buttonWidth,
                                  height: Themes.buttonHeight,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Themes.borderRadius),
                                    color: Color(filesProvider.mainColor),
                                    image: const DecorationImage(
                                      image: AssetImage(Themes.doubleBorderAsset),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(Themes.buttonPadding),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.language_rounded,
                                          color: Color(filesProvider.fontColor),
                                          semanticLabel: translate("popup.new_column"),
                                        ),
                                        Icon(
                                          Icons.add_rounded,
                                          color: Color(filesProvider.fontColor),
                                          semanticLabel: translate("popup.new_column"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: Themes.spacerHeight,
                                width: Themes.spacerWidth,
                              ),
                              // Aggiunge una colonna di bard-public
                              GestureDetector(
                                onTap: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return const BardPublicColumnSettingsDialog(
                                        newCol: true,
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  width: buttonWidth,
                                  height: Themes.buttonHeight,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(Themes.borderRadius),
                                    color: Color(filesProvider.mainColor),
                                    image: const DecorationImage(
                                      image: AssetImage(Themes.doubleBorderAsset),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(Themes.buttonPadding),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.record_voice_over_rounded,
                                          color: Color(filesProvider.fontColor),
                                          semanticLabel: translate("popup.new_column"),
                                        ),
                                        Icon(
                                          Icons.add_rounded,
                                          color: Color(filesProvider.fontColor),
                                          semanticLabel: translate("popup.new_column"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Tutte le altre colonne vengono costruite
                        String columnId = filesProvider.columnCharacteristics.keys.elementAt(colIndex);

                        return MusicColumn(
                          columnId: columnId,
                          provider: filesProvider,
                          columnWidth: columnWidth,
                          buttonWidth: buttonWidth,
                          db: db,
                        );
                      }
                    },
                    separatorBuilder: (BuildContext context, int colIndex) {
                      return const VerticalDivider(
                        color: Colors.black,
                        thickness: 0.5,
                        width: 20.0,
                        indent: 15.0,
                        endIndent: 50.0,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
