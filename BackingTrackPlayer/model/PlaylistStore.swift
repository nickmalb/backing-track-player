import Foundation
import Observation

@Observable
@MainActor
final class PlaylistStore {
    private(set) var playlists: [Playlist] = []

    private let storageKey = "playlists.v1"

    init() {
        load()
        if playlists.isEmpty {
            playlists = [Self.defaultPlaylist]
            save()
        }
    }

    func add(_ playlist: Playlist) {
        playlists.append(playlist)
        save()
    }

    func delete(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(playlists) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Playlist].self, from: data) else { return }
        playlists = decoded
    }

    static var defaultPlaylist: Playlist {
        Playlist(name: "Backing Tracks", tracks: [
            Track(title: "Blind", filePath: "Backing Tracks/Blind_BT", fileType: "wav"),
            Track(title: "In The Pines", filePath: "Backing Tracks/In The Pines_BT", fileType: "wav"),
            Track(title: "Legacy", filePath: "Backing Tracks/Legacy_BT", fileType: "wav"),
            Track(title: "Sense Control", filePath: "Backing Tracks/Sense Control_BT", fileType: "wav"),
            Track(title: "When Morning Came", filePath: "Backing Tracks/When Morning Came_BT", fileType: "wav"),
        ])
    }
}
