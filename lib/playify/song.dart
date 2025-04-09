class Song {
  Song(
      {required this.songID,
      required this.title,
      required this.artistName,
      required this.albumTitle,
      required this.trackNumber,
      required this.playCount,
      required this.discNumber,
      required this.genre,
      required this.releaseDate,
      required this.duration,
      required this.isExplicit});

  ///The title of the album.
  String albumTitle;

  ///The name of the song artist.
  String artistName;

  ///The release date of the song.
  DateTime releaseDate;

  ///The genre of the song.
  String genre;

  ///The title of the song.
  String title;

  ///The Persistent Song ID of the song. Used to play or enqueue a song.
  String songID;

  ///The track number of the song in an album.
  int trackNumber;

  ///The amount of times the song has been played.
  int playCount;

  ///The disc number the song belongs to in an album.
  int discNumber;

  ///The total duration of the song.
  double duration;

  ///Shows if the song is explicit.
  bool isExplicit;

  static Song fromJson(Map<String, dynamic> map) => Song(
        albumTitle: (map["albumTitle"] ?? "").toString(),
        duration: map['playbackDuration'] as double,
        title: (map["songTitle"] ?? "").toString(),
        trackNumber: map['trackNumber'] as int,
        discNumber: map['discNumber'] as int,
        isExplicit: map['isExplicitItem'] as bool,
        genre: (map["genre"] ?? "").toString(),
        releaseDate: DateTime.fromMillisecondsSinceEpoch(map['releaseDate'] as int),
        playCount: map['playCount'] as int,
        artistName: (map["artist"] ?? "").toString(),
        songID: (map['songID'] ?? '').toString(),
      );

  @override
  String toString() {
    return 'Song Title: $title, Album Title: $albumTitle, Artist Name: $artistName, Duration: $duration, SongID: $songID\n';
  }
}
