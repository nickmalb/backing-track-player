import Foundation

struct Playlist: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var tracks: [Track]

    init(id: UUID = UUID(), name: String, tracks: [Track] = []) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
}
