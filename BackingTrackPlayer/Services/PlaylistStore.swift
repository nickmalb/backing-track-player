import Foundation
import Observation

@Observable
@MainActor
final class PlaylistStore {
    private(set) var playlists: [Playlist] = []

    private let storageKey = "playlists.v1"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
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

    func move(from source: IndexSet, to destination: Int) {
        playlists.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func renamePlaylist(_ playlist: Playlist, to newName: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].name = newName
        save()
    }

    func addTracks(_ tracks: [Track], to playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[index].tracks.append(contentsOf: tracks)
        save()
    }

    func deleteTracks(at offsets: IndexSet, from playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[index].tracks.remove(atOffsets: offsets)
        save()
    }

    func moveTracks(from source: IndexSet, to destination: Int, in playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[index].tracks.move(fromOffsets: source, toOffset: destination)
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(playlists) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey),
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
