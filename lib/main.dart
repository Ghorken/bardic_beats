import 'dart:io';
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bardic_beats/firebase_options.dart';

import 'package:bardic_beats/settings_page.dart';
import 'package:bardic_beats/ad_helper.dart';
import 'package:bardic_beats/files_provider.dart';
import 'package:bardic_beats/music_page.dart';
import 'package:bardic_beats/utility/themes.dart';
import 'package:bardic_beats/utility/translate_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  var delegate = await LocalizationDelegate.create(
    fallbackLocale: "en",
    supportedLocales: [
      "en",
      "es",
      "fr",
      "it",
      "de",
    ],
    preferences: TranslatePreferences(),
  );
  runApp(
    LocalizedApp(
      delegate,
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => FilesProvider())],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var localizationDelegate = LocalizedApp.of(context).delegate;

    final FilesProvider filesProvider = Provider.of<FilesProvider>(context, listen: false);
    filesProvider.getFilesList();
    filesProvider.getSettings();
    filesProvider.getBackgroundImages();

    return LocalizationProvider(
      state: LocalizationProvider.of(context).state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: Themes.appName,
        localizationsDelegates: [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate, localizationDelegate],
        supportedLocales: localizationDelegate.supportedLocales,
        locale: localizationDelegate.currentLocale,
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ValueNotifier<double> _notifier;

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _notifier = ValueNotifier<double>(0);
    AdHelper.homeBanner.load();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final FilesProvider filesProvider = Provider.of<FilesProvider>(context, listen: true);
    final AdWidget adWidget = AdWidget(ad: AdHelper.homeBanner);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final Image backgroundImg;

    // Determina come caricare l'immagine di background verificando se è presa dagli asset o meno
    if (filesProvider.backgroundImg.contains("assets")) {
      backgroundImg = Image.asset(filesProvider.backgroundImg, height: mediaQuery.size.height, fit: BoxFit.fitHeight);
    } else {
      backgroundImg = Image.file(File(filesProvider.backgroundImg), height: mediaQuery.size.height, fit: BoxFit.fitHeight);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //Gestisco le tab dell`app
      home: Scaffold(
        backgroundColor: Color(filesProvider.backgroundColor),
        appBar: AppBar(
          backgroundColor: Color(filesProvider.mainColor),
          title: Text(
            Themes.appName,
            style: TextStyle(color: Color(filesProvider.fontColor)),
          ),
          actions: [
            // Bottone delle impostazioni
            IconButton(
              icon: Icon(
                Icons.settings_rounded,
                color: Color(filesProvider.fontColor),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<dynamic>(builder: (BuildContext context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            (filesProvider.backgroundImg == "none")
                ? const SizedBox.shrink()
                : OverflowBox(
                    maxWidth: mediaQuery.size.width * 10.0,
                    alignment: Alignment.topLeft,
                    child: AnimatedBuilder(
                      animation: _notifier,
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(-_notifier.value, 0),
                          child: backgroundImg,
                        );
                      },
                    ),
                  ),
            MusicPage(notifier: _notifier),
          ],
        ),
        bottomNavigationBar: Container(height: Themes.adBarHeight, color: Color(filesProvider.mainColor), child: adWidget),
      ),
    );
  }
}
