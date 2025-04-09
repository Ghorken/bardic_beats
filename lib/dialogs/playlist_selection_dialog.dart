import 'package:bardic_beats/playify/playlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:bardic_beats/utility/themes.dart';

class PlaylistSelectionDialog extends StatefulWidget {
  const PlaylistSelectionDialog({super.key, required this.playlists, required this.dirColor, required this.fontColor});

  final List<Playlist> playlists;
  final int dirColor;
  final int fontColor;

  @override
  State<PlaylistSelectionDialog> createState() => _PlaylistSelectionDialogState();
}

// Popup dialog esclusivo per iOS per selezionare la playlist da associare alla colonna
class _PlaylistSelectionDialogState extends State<PlaylistSelectionDialog> {
  late List<Playlist> playlists;
  late int dirColor;
  late int fontColor;

  final ScrollController verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.playlists.retainWhere((playlist) => playlist.songs.isNotEmpty);
    playlists = widget.playlists;
    dirColor = widget.dirColor;
    fontColor = widget.fontColor;
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);
    double dialogWidth = mediaQuery.size.width / 3;
    double dialogHeight = mediaQuery.size.height / 2;
    double buttonWidth = mediaQuery.size.width / 5;

    return AlertDialog(
      title: Container(
        padding: const EdgeInsets.all(Themes.columnFontSize),
        alignment: Alignment.center,
        child: Text(
          translate("popup.choose_playlist"),
          style: const TextStyle(
            fontSize: Themes.columnFontSize,
            color: Colors.black,
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Crea la lista di playlist presenti sul device
          SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Scrollbar(
              radius: const Radius.circular(Themes.borderRadius),
              child: ListView.separated(
                scrollDirection: Axis.vertical,
                controller: verticalScrollController,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: playlists.length,
                itemBuilder: (BuildContext context, int rowIndex) {
                  return buildButton(context, rowIndex, buttonWidth);
                },
                separatorBuilder: (BuildContext context, int rowIndex) {
                  return const SizedBox(
                    height: Themes.spacerHeight,
                    width: Themes.spacerWidth,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Crea un pulsante per gli album
  Widget buildButton(BuildContext context, int rowIndex, double buttonWidth) {
    return SizedBox(
      width: buttonWidth,
      child: GestureDetector(
        onTap: () {
          //Restituisce l'id e il nome
          Navigator.pop(context, [playlists[rowIndex].title, playlists[rowIndex].playlistID]);
        },
        child: Container(
          width: buttonWidth,
          height: Themes.buttonHeight,
          margin: const EdgeInsets.all(Themes.buttonMargin),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(dirColor),
            image: const DecorationImage(
              image: AssetImage(Themes.doubleBorderAsset),
              fit: BoxFit.fill,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Themes.buttonPadding),
            child: Text(
              playlists[rowIndex].title,
              maxLines: 2,
              style: TextStyle(
                fontSize: Themes.columnFontSize,
                color: Color(fontColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
