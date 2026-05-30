import SwiftUI

@main
struct BackingTrackPlayerApp: App {
    @State private var playlistStore: PlaylistStore
    @State private var trackPlayer: TrackPlayer

    init() {
        let store = PlaylistStore()
        let firstPlaylist = store.playlists.first ?? Playlist(name: "Empty")
        _playlistStore = State(initialValue: store)
        _trackPlayer = State(initialValue: TrackPlayer(playlist: firstPlaylist))
    }

    var body: some Scene {
        WindowGroup {
            MainView(playlistStore: playlistStore, trackPlayer: trackPlayer)
        }
    }
}
