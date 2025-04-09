import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:bardic_beats/utility/column_dialog_functions.dart';
import 'package:bardic_beats/utility/themes.dart';
import 'package:bardic_beats/dialogs/background_dialog.dart';
import 'package:bardic_beats/files_provider.dart';
import 'package:bardic_beats/ad_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late FilesProvider filesProvider;

  @override
  void initState() {
    AdHelper.settingsBanner.load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    filesProvider = Provider.of<FilesProvider>(context, listen: true);
    final AdWidget adWidget = AdWidget(ad: AdHelper.settingsBanner);
    MediaQueryData mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          translate('settings_page.settings'),
          style: TextStyle(color: Color(filesProvider.fontColor)),
        ),
        iconTheme: IconThemeData(
          color: Color(filesProvider.fontColor),
        ),
        backgroundColor: Color(filesProvider.mainColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Permette di scegliere la lingua dell'applicazione
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${translate("settings_page.language")}: ",
                  style: const TextStyle(fontSize: Themes.settingsFontSize),
                ),
                DropdownButton<String>(
                  value: filesProvider.language,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: Themes.iconSize,
                  elevation: Themes.dropdownButtonElevation,
                  style: const TextStyle(color: Colors.black, fontSize: Themes.settingsFontSize),
                  underline: Container(
                    height: Themes.underlineHeight,
                    color: Colors.black,
                  ),
                  onChanged: (String? data) async {
                    if (data != null) {
                      changeLocale(context, data);

                      await FirebaseAnalytics.instance.logEvent(
                        name: "change_language",
                        parameters: {
                          "language": data,
                        },
                      );
                      setState(() {
                        filesProvider.setLanguage(data);
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem<String>(value: "en", child: Text(translate("languages.english"))),
                    DropdownMenuItem<String>(value: "it", child: Text(translate("languages.italian"))),
                    DropdownMenuItem<String>(value: "fr", child: Text(translate("languages.french"))),
                    DropdownMenuItem<String>(value: "es", child: Text(translate("languages.spanish"))),
                    DropdownMenuItem<String>(value: "de", child: Text(translate("languages.german"))),
                  ],
                ),
              ],
            ),
            // Mantiene schermo sempre attivo
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${translate("settings_page.screen_always_on")}: ",
                  style: const TextStyle(fontSize: Themes.settingsFontSize),
                ),
                Switch(
                  value: filesProvider.screenAlwaysOn,
                  onChanged: (value) {
                    setState(() {
                      filesProvider.setScreenAlwaysOn(value);
                    });
                  },
                  activeColor: Color(filesProvider.mainColor),
                ),
              ],
            ),
            // Colore di base
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${translate("settings_page.base_color")}: ",
                  style: const TextStyle(fontSize: Themes.settingsFontSize),
                ),
                ColorIndicator(
                  width: 35,
                  height: 35,
                  borderRadius: 4,
                  color: Color(filesProvider.mainColor),
                  onSelectFocus: false,
                  onSelect: () async {
                    final int colorBeforeDialog = filesProvider.mainColor;
                    // Se la scelta non viene confermata ripristina il colore precedente
                    if (!(await colorPickerDialog(context, filesProvider.mainColor, false, (Color color) {
                      setState(() {
                        filesProvider.setMainColor(color.value);
                      });
                    }))) {
                      setState(() {
                        filesProvider.setMainColor(colorBeforeDialog);
                      });
                    }
                  },
                ),
              ],
            ),
            // Colore del font
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${translate("settings_page.font_color")}: ",
                  style: const TextStyle(fontSize: Themes.settingsFontSize),
                ),
                DropdownButton<int>(
                  value: filesProvider.fontColor,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: Themes.iconSize,
                  elevation: Themes.dropdownButtonElevation,
                  style: const TextStyle(color: Colors.black, fontSize: Themes.settingsFontSize),
                  underline: Container(
                    height: Themes.underlineHeight,
                    color: Colors.black,
                  ),
                  onChanged: (int? data) {
                    if (data != null) {
                      setState(() {
                        filesProvider.setFontColor(data);
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem<int>(
                        value: Themes.blackValue,
                        child: Text(
                          translate("colors.black"),
                        )),
                    DropdownMenuItem<int>(
                        value: Themes.whiteValue,
                        child: Text(
                          translate("colors.white"),
                        ))
                  ],
                ),
              ],
            ),
            // Sfondo
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${translate("settings_page.background")}: ",
                  style: const TextStyle(
                    fontSize: Themes.settingsFontSize,
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: GestureDetector(
                    // Visualizzo l'anteprima in base al tipo di immagine scelta (none, asset, custom)
                    child: (filesProvider.backgroundImg == "none")
                        ? SizedBox(
                            width: Themes.settingsBackgroundImageWidth,
                            height: Themes.settingsBackgroundImageHeight,
                            child: ColoredBox(
                              color: Color(filesProvider.backgroundColor),
                            ),
                          )
                        : (filesProvider.backgroundImg.contains("assets"))
                            ? Image.asset(
                                filesProvider.backgroundImg,
                                width: Themes.settingsBackgroundImageWidth,
                                height: Themes.settingsBackgroundImageHeight,
                              )
                            : Image.file(
                                File(filesProvider.backgroundImg),
                                width: Themes.settingsBackgroundImageWidth,
                                height: Themes.settingsBackgroundImageHeight,
                              ),
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return const BackgroundDialog();
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.drive_file_rename_outline),
                  color: Colors.grey,
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return const BackgroundDialog();
                      },
                    );
                  },
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LimitedBox(
                  maxWidth: mediaQuery.size.width,
                  child: Text(
                    translate("settings_page.two_minute_tabletop_attribution"),
                    style: const TextStyle(
                      fontSize: Themes.creditsFontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  child: Text(
                    translate("settings_page.attribution_link"),
                    style: TextStyle(
                      fontSize: Themes.creditsFontSize,
                      color: Color(filesProvider.mainColor),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () async =>
                      await canLaunchUrlString("https://2minutetabletop.com/") ? await launchUrlString("https://2minutetabletop.com/") : throw translate("settings_page.url_error"),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LimitedBox(
                  maxWidth: mediaQuery.size.width,
                  child: Text(
                    translate("settings_page.signal_bug_request_feature"),
                    style: const TextStyle(
                      fontSize: Themes.creditsFontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  child: Text(
                    translate("settings_page.click_here"),
                    style: TextStyle(
                      fontSize: Themes.creditsFontSize,
                      color: Color(filesProvider.mainColor),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () async => await canLaunchUrlString("https://docs.google.com/forms/d/e/1FAIpQLScmcQg2ZTiimjaYGdSFyZv65Yc0YX-nsKBVxTpksiW3YqTeHw/viewform")
                      ? await launchUrlString("https://docs.google.com/forms/d/e/1FAIpQLScmcQg2ZTiimjaYGdSFyZv65Yc0YX-nsKBVxTpksiW3YqTeHw/viewform")
                      : throw translate("settings_page.url_error"),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LimitedBox(
                  maxWidth: mediaQuery.size.width,
                  child: Text(
                    translate("settings_page.need_privacy"),
                    style: const TextStyle(
                      fontSize: Themes.creditsFontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  child: Text(
                    translate("settings_page.privacy_text"),
                    style: TextStyle(
                      fontSize: Themes.creditsFontSize,
                      color: Color(filesProvider.mainColor),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () async => await canLaunchUrlString("https://www.termsfeed.com/live/87b4bdbc-4836-489c-bd47-532fe4a2adef")
                      ? await launchUrlString("https://www.termsfeed.com/live/87b4bdbc-4836-489c-bd47-532fe4a2adef")
                      : throw translate("settings_page.url_error"),
                ),
              ],
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: Themes.adBarHeight,
        color: Color(filesProvider.mainColor),
        child: adWidget,
      ),
    );
  }
}
