import UIKit
import Flutter
import MediaPlayer

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var player: MPMusicPlayerController = MPMusicPlayerController.systemMusicPlayer

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let playlistsChannel = FlutterMethodChannel(name: "rpg.indice.bardicbeats/playlists", binaryMessenger: controller.binaryMessenger)
    playlistsChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        // This method is invoked on the UI thread.
        switch call.method {
          case "getPlaylists":
            let playlists = self.getPlaylists()
            let res: [[String: Any]] = playlists?.map({ playlist in
              [
                "title": playlist.value(forProperty: MPMediaPlaylistPropertyName) ?? "",
                "playlistID": playlist.persistentID,
                "songs": playlist.items.map({song in
                    song.toDict()
                })
              ]
            }) ?? []
            result(res)
          case "playItem":
            guard let args = call.arguments as? [String: Any] else {
              result(FlutterError(code: "invalidArgs", message: "Invalid Arguments", details: "The arguments were not provided!"))
              return
            }
            guard let songID = args["songID"] as? String else {
              result(FlutterError(code: "invalidArgs", message: "Invalid Arguments", details: "The parameter songID was not provided!"))
              return
            }
            self.playItem(songID: songID)
            result(nil)
          case "play":
            self.play()
            result(nil)
          case "pause":
            self.pause()
            result(nil)
          default:
            result(FlutterMethodNotImplemented)
            return
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  func getPlaylists() -> [MPMediaItemCollection]? {
    let query = MPMediaQuery.playlists()
    if let playlists = query.collections {
      return playlists
    }
    return nil
  }

  func playItem(songID: String) {
    let song = getMediaItemsWithIDs(songIDs: [songID])
    let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: song))
    
    player.setQueue(with: descriptor)
    player.prepareToPlay(completionHandler: {error in
      if error == nil {
        self.player.play()
      }
    })
  }

  ///Get MediaItems via a PersistentID using predicates and queries.
  private func getMediaItemsWithIDs(songIDs: [String]) -> [MPMediaItem] {
    var songs: [MPMediaItem] = []
    for songID in songIDs {
      let songFilter = MPMediaPropertyPredicate(value: songID, forProperty: MPMediaItemPropertyPersistentID, comparisonType: .equalTo)
      let query = MPMediaQuery(filterPredicates: Set([songFilter]))
      if let items = query.items, let first = items.first {
        songs.append(first)
      }
    }
    return songs
  }

  func play() {
    player.play()
  }

  func pause() {
    player.pause()
  }
    
}

extension MPMediaItem {
  ///Returns a dicationary without the image data set.
  func toDict() -> [String: Any] {
    return [
      "artist": artist ?? "",
      "songTitle": title ?? "",
      "albumTitle": albumTitle ?? "",
      "trackNumber": albumTrackNumber,
      "albumTrackNumber": albumTrackNumber,
      "albumTrackCount": albumTrackCount,
      "genre": genre ?? "",
      "releaseDate": Int64((releaseDate?.timeIntervalSince1970 ?? 0) * 1000),
      "playCount": playCount,
      "discCount": discCount,
      "discNumber": discNumber,
      "isExplicitItem": isExplicitItem,
      "songID": persistentID,
      "playbackDuration": playbackDuration
    ]
  }
}
