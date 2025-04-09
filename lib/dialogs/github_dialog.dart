import 'package:bardic_beats/utility/column_dialog_functions.dart';
import 'package:bardic_beats/utility/themes.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GithubDialog extends StatelessWidget {
  final int mainColor;
  final int fontColor;
  final NavigatorState navigator;

  const GithubDialog({
    super.key,
    required this.mainColor,
    required this.fontColor,
    required this.navigator,
  });

  @override
  Widget build(BuildContext context) {
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
          translate("github.header"),
          style: TextStyle(
            fontSize: Themes.headerFontSize,
            color: Color(fontColor),
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: translate("github.signup_in_a"),
                    style: const TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text: translate("github.signup_in_b"),
                    style: TextStyle(
                      fontSize: Themes.creditsFontSize,
                      color: Color(mainColor),
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap =
                          () async => await canLaunchUrlString("https://github.com/") ? await launchUrlString("https://github.com/") : throw translate("settings_page.url_error"),
                  ),
                  TextSpan(
                    text: translate("github.signup_in_c"),
                    style: const TextStyle(color: Colors.black),
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
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(0);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/00_signup_a.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(1);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/01_signup_b.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(2);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/02_signup_c.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
            Text(
              translate("github.account"),
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(3);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/03_account_a.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(4);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/04_account_b.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(5);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/05_account_c.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
            Text(
              translate("github.repository"),
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(6);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/06_repository_a.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(7);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/07_repository_b.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
            Text(
              translate("github.upload_files"),
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(8);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/08_upload_a.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(9);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/09_upload_b.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(10);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/10_upload_c.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
            Text(
              translate("github.column"),
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(11);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/11_column_a.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      MultiImageProvider multiImageProvider = await githubImages(12);
                      if (context.mounted) showImageViewerPager(context, multiImageProvider, immersive: false, infinitelyScrollable: true);
                    },
                    child: Image.asset(
                      "assets/Github/12_column_b.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: Themes.spacerHeight,
              width: Themes.spacerWidth,
            ),
            Text(
              translate("github.footer"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Chiude il popup
            navigator.pop();
          },
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontSize: Themes.columnSettingsFontSize),
            foregroundColor: Colors.black,
          ),
          child: Text(translate("github.understood")),
        ),
      ],
    );
  }
}
