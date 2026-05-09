import SwiftUI

@main
struct BackingTrackPlayerApp: App {
    @State private var trackPlayer = TrackPlayer(tracks: [
        Track(title: "Blind", filePath: "Backing Tracks/Blind_BT", fileType: "wav"),
        Track(title: "In The Pines", filePath: "Backing Tracks/In The Pines_BT", fileType: "wav"),
        Track(title: "Legacy", filePath: "Backing Tracks/Legacy_BT", fileType: "wav"),
        Track(title: "Sense Control", filePath: "Backing Tracks/Sense Control_BT", fileType: "wav"),
        Track(title: "When Morning Came", filePath: "Backing Tracks/When Morning Came_BT", fileType: "wav"),
    ])

    var body: some Scene {
        WindowGroup {
            PlayerView(trackPlayer: trackPlayer)
        }
    }
}
