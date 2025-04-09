import 'dart:async';
import 'package:bardic_beats/playify/song.dart';
import 'package:flutter/services.dart';
import 'package:bardic_beats/playify/playlist.dart';

class Playify {
  static const MethodChannel platform = MethodChannel("rpg.indice.bardicbeats/playlists");

  ///Get all the playlists.
  Future<List<Playlist>?> getPlaylists() async {
    final List<dynamic>? result = await platform.invokeMethod<List<dynamic>>('getPlaylists');
    final List<Map<String, dynamic>>? playlistMaps = result?.map((dynamic playlist) => Map<String, dynamic>.from(playlist as Map)).toList();

    final playlists = playlistMaps
        ?.map<Playlist>((Map<String, dynamic> playlist) => Playlist(
              songs: List<Song>.from((playlist['songs'] as List).map((dynamic song) => Song.fromJson(Map<String, dynamic>.from(song as Map)))),
              title: playlist['title'].toString(),
              playlistID: playlist['playlistID'].toString(),
            ))
        .toList();

    return playlists;
  }

  ///Play a single song by giving its [songID].
  Future<void> playItem({required String songID}) async {
    await platform.invokeMethod('playItem', <String, dynamic>{'songID': songID});
  }

  ///Play the most recent queue.
  Future<void> play() async {
    await platform.invokeMethod('play');
  }

  ///Pause playing.
  Future<void> pause() async {
    await platform.invokeMethod('pause');
  }
}
