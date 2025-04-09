import 'dart:io';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:bardic_beats/utility/column_dialog_functions.dart';
import 'package:bardic_beats/files_provider.dart';
import 'package:bardic_beats/utility/themes.dart';

// Dialog che contiene l'immagine di sfondo
class BackgroundDialog extends StatefulWidget {
  const BackgroundDialog({super.key});

  @override
  State<BackgroundDialog> createState() => _BackgroundDialogState();
}

class _BackgroundDialogState extends State<BackgroundDialog> {
  late FilesProvider filesProvider;
  late int mainColor;
  late int fontColor;
  late String selected;
  late int backgroundColor;

  @override
  void initState() {
    super.initState();

    // Recupera le impostazioni generali
    filesProvider = Provider.of<FilesProvider>(context, listen: false);
    mainColor = filesProvider.mainColor;
    fontColor = filesProvider.fontColor;
    selected = filesProvider.backgroundImg;
    backgroundColor = filesProvider.backgroundColor;
  }

  @override
  Widget build(BuildContext context) {
    NavigatorState navigator = Navigator.of(context);
    MediaQueryData mediaQuery = MediaQuery.of(context);
    double dialogHeight = mediaQuery.size.height / 3;

    List<String> backgroundImages = filesProvider.backgroundImages;

    return AlertDialog(
      title: Container(
        padding: const EdgeInsets.all(Themes.padding),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(mainColor),
          image: const DecorationImage(
            image: AssetImage(Themes.singleBorderAsset),
            fit: BoxFit.fill,
          ),
        ),
        child: Text(
          translate("settings_page.background"),
          style: TextStyle(
            fontSize: Themes.headerFontSize,
            color: Color(fontColor),
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visualizza le immagini da poter usare come background
          SizedBox(
            width: mediaQuery.size.width,
            height: dialogHeight,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 5.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: backgroundImages.length,
              itemBuilder: (context, imgIndex) {
                // Se l'immagine è vuota visualizza uno sfondo monocolore
                if (backgroundImages[imgIndex] == "none") {
                  return GestureDetector(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                      decoration: BoxDecoration(
                        border: selected == backgroundImages[imgIndex]
                            ? Border.all(color: Color(mainColor), width: 2.0)
                            : Border.all(
                                color: Colors.transparent,
                              ),
                      ),
                      child: SizedBox(
                        width: Themes.settingsBackgroundImageWidth,
                        height: Themes.settingsBackgroundImageHeight,
                        child: ColoredBox(
                          color: Color(backgroundColor),
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selected = "none";
                      });
                    },
                  );
                } else if (backgroundImages[imgIndex].contains("assets")) {
                  // Se è un'immagine di asset
                  return GestureDetector(
                    child: Container(
                      decoration: BoxDecoration(
                        border: selected == backgroundImages[imgIndex]
                            ? Border.all(color: Color(mainColor), width: 2.0)
                            : Border.all(
                                color: Colors.transparent,
                              ),
                      ),
                      child: Image.asset(
                        backgroundImages[imgIndex],
                        width: Themes.settingsBackgroundImageWidth,
                        height: Themes.settingsBackgroundImageHeight,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selected = backgroundImages[imgIndex];
                      });
                    },
                  );
                } else {
                  // Se è un'immagine custom
                  return GestureDetector(
                    child: Container(
                      decoration: BoxDecoration(
                        border: selected == backgroundImages[imgIndex]
                            ? Border.all(color: Color(mainColor), width: 2.0)
                            : Border.all(
                                color: Colors.transparent,
                              ),
                      ),
                      child: Image.file(
                        File(backgroundImages[imgIndex]),
                        width: Themes.settingsBackgroundImageWidth,
                        height: Themes.settingsBackgroundImageHeight,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selected = backgroundImages[imgIndex];
                      });
                    },
                  );
                }
              },
            ),
          ),
          const SizedBox(
            height: Themes.spacerHeight,
            width: Themes.spacerWidth,
          ),
          // Se è stato scelto lo sfondo mono colore permette di scegliere il colore
          SizedBox(
            height: Themes.selectColorRowHeight,
            child: (selected != "none")
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${translate("settings_page.background_color")}: ",
                        style: const TextStyle(fontSize: Themes.settingsFontSize),
                      ),
                      ColorIndicator(
                        width: 35,
                        height: 35,
                        borderRadius: 4,
                        color: Color(backgroundColor),
                        onSelectFocus: false,
                        onSelect: () async {
                          final int colorBeforeDialog = backgroundColor;
                          // Se la scelta non viene confermata ripristina il colore precedente
                          if (!(await colorPickerDialog(context, backgroundColor, false, (Color color) {
                            setState(() {
                              backgroundColor = color.value;
                            });
                          }))) {
                            setState(() {
                              backgroundColor = colorBeforeDialog;
                            });
                          }
                        },
                      ),
                    ],
                  ),
          ),
          const SizedBox(
            height: Themes.spacerHeight,
            width: Themes.spacerWidth,
          ),
          Row(
            children: [
              // Permette di caricare un'immagine personalizzata
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: Themes.buttonElevation,
                  backgroundColor: Color(mainColor),
                  foregroundColor: Color(fontColor),
                  padding: const EdgeInsets.all(Themes.padding),
                ),
                onPressed: () async {
                  // Apre l'image picker
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  // Se è stata scelta un'immagine la aggiunge all'elenco e la seleziona
                  if (image != null) {
                    setState(() {
                      filesProvider.addBackgroundImage(image.path);
                      selected = image.path;
                    });
                  }
                },
                child: const Icon(Icons.add_photo_alternate_rounded),
              ),
              const SizedBox(
                height: Themes.spacerHeight,
                width: Themes.spacerWidth,
              ),
              // Permette di eliminare un'immagine personalizzata
              if (!selected.contains("assets") && selected != "none")
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: Themes.buttonElevation,
                    backgroundColor: Color(mainColor),
                    foregroundColor: Color(fontColor),
                    padding: const EdgeInsets.all(Themes.padding),
                  ),
                  onPressed: () async {
                    setState(() {
                      // Elimina l'immagine selezionata
                      filesProvider.deleteBackgroundImage(selected);
                      // Seleziona la prima dell'elenco
                      selected = backgroundImages[0];
                      // Salva la selezione così da non mostrare più quella cancellata
                      filesProvider.setBackgroundImg(selected);
                    });
                  },
                  child: const Icon(Icons.delete_rounded),
                ),
            ],
          ),
        ],
      ),
      actions: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          TextButton(
            onPressed: () {
              // Chiude il popup
              navigator.pop();
            },
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: Themes.settingsFontSize),
            ),
            child: Text(translate("popup.abort")),
          ),
          TextButton(
            onPressed: () {
              if (selected == "none") {
                filesProvider.setBackgroundColor(backgroundColor);
              }
              filesProvider.setBackgroundImg(selected);
              navigator.pop();
            },
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: Themes.settingsFontSize),
            ),
            child: Text(translate("popup.save")),
          ),
        ])
      ],
    );
  }
}
