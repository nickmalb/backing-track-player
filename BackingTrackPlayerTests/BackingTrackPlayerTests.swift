import Foundation
import Testing
@testable import BackingTrackPlayer

@MainActor
@Suite("TrackPlayer", .serialized)
struct TrackPlayerTests {
    let playlist = Playlist(name: "Test", tracks: [
        Track(title: "Blind", filePath: "Backing Tracks/Blind_BT", fileType: "wav"),
        Track(title: "In The Pines", filePath: "Backing Tracks/In The Pines_BT", fileType: "wav"),
        Track(title: "Legacy", filePath: "Backing Tracks/Legacy_BT", fileType: "wav"),
        Track(title: "Sense Control", filePath: "Backing Tracks/Sense Control_BT", fileType: "wav"),
        Track(title: "When Morning Came", filePath: "Backing Tracks/When Morning Came_BT", fileType: "wav"),
    ])

    @Test("Default playlist tracks ordered alphabetically matching folder order")
    func defaultPlaylistOrder() {
        let defaultPlaylist = PlaylistStore.defaultPlaylist
        #expect(defaultPlaylist.tracks[0].title == "Blind")
        #expect(defaultPlaylist.tracks[1].title == "In The Pines")
        #expect(defaultPlaylist.tracks[2].title == "Legacy")
        #expect(defaultPlaylist.tracks[3].title == "Sense Control")
        #expect(defaultPlaylist.tracks[4].title == "When Morning Came")
    }

    @Test("First track is loaded on init")
    func firstTrackLoadedOnInit() {
        let player = TrackPlayer(playlist: playlist)
        #expect(player.currentTrackIndex == 0)
        #expect(player.currentTrack?.title == "Blind")
        #expect(player.isPlaying == false)
    }

    @Test("Play starts playback")
    func playStartsPlayback() {
        let player = TrackPlayer(playlist: playlist)
        player.play()
        #expect(player.isPlaying == true)
    }

    @Test("Stop stops playback")
    func stopStopsPlayback() {
        let player = TrackPlayer(playlist: playlist)
        player.play()
        player.stop()
        #expect(player.isPlaying == false)
    }

    @Test("Play after stop resumes without changing track")
    func playAfterStop() {
        let player = TrackPlayer(playlist: playlist)
        player.play()
        player.stop()
        player.play()
        #expect(player.isPlaying == true)
        #expect(player.currentTrackIndex == 0)
    }

    @Test("Rewind stops playback and resets to beginning")
    func rewindResetsToBeginning() {
        let player = TrackPlayer(playlist: playlist)
        player.play()
        player.rewind()
        #expect(player.isPlaying == false)
        #expect(player.currentTime == 0)
        #expect(player.currentTrackIndex == 0)
    }

    @Test("Rewind at beginning loads previous track")
    func rewindAtBeginningLoadsPreviousTrack() {
        let player = TrackPlayer(playlist: playlist)
        player.skip()
        #expect(player.currentTrackIndex == 1)

        // Position is 0 after skip (just loaded), so rewind goes to previous track
        player.rewind()
        #expect(player.currentTrackIndex == 0)
        #expect(player.currentTrack?.title == "Blind")
    }

    @Test("Rewind at beginning of first track stays on first track")
    func rewindAtFirstTrackStays() {
        let player = TrackPlayer(playlist: playlist)
        player.rewind()
        player.rewind()
        #expect(player.currentTrackIndex == 0)
        #expect(player.currentTrack?.title == "Blind")
    }

    @Test("Skip advances to next track without starting playback")
    func skipAdvancesWithoutPlaying() {
        let player = TrackPlayer(playlist: playlist)
        player.skip()
        #expect(player.currentTrackIndex == 1)
        #expect(player.currentTrack?.title == "In The Pines")
        #expect(player.isPlaying == false)
    }

    @Test("Skip stops playback if playing")
    func skipStopsPlayback() {
        let player = TrackPlayer(playlist: playlist)
        player.play()
        player.skip()
        #expect(player.isPlaying == false)
        #expect(player.currentTrackIndex == 1)
    }

    @Test("Skip wraps around to first track after last")
    func skipWrapsAround() {
        let player = TrackPlayer(playlist: playlist)
        for _ in 0..<playlist.tracks.count {
            player.skip()
        }
        #expect(player.currentTrackIndex == 0)
        #expect(player.currentTrack?.title == "Blind")
    }

    @Test("Skip through all tracks visits each in order")
    func skipThroughAllTracks() {
        let player = TrackPlayer(playlist: playlist)
        for i in 0..<playlist.tracks.count {
            #expect(player.currentTrack?.title == playlist.tracks[i].title)
            player.skip()
        }
    }

    @Test("Track has positive duration after loading")
    func trackHasDuration() {
        let player = TrackPlayer(playlist: playlist)
        #expect(player.duration > 0)
    }

    @Test("Current time resets when loading new track via skip")
    func currentTimeResetsOnSkip() {
        let player = TrackPlayer(playlist: playlist)
        player.play()
        player.skip()
        #expect(player.currentTime == 0)
    }

    @Test("Loading new playlist resets to first track")
    func loadPlaylistResetsState() {
        let player = TrackPlayer(playlist: playlist)
        player.skip()
        player.skip()
        #expect(player.currentTrackIndex == 2)

        let newPlaylist = Playlist(name: "Other", tracks: [
            Track(title: "Legacy", filePath: "Backing Tracks/Legacy_BT", fileType: "wav"),
            Track(title: "Blind", filePath: "Backing Tracks/Blind_BT", fileType: "wav"),
        ])
        player.loadPlaylist(newPlaylist)
        #expect(player.currentTrackIndex == 0)
        #expect(player.currentTrack?.title == "Legacy")
        #expect(player.isPlaying == false)
    }

    @Test("Bundle source resolves to a bundle URL")
    func bundleSourceURL() {
        let track = Track(title: "Blind", filePath: "Backing Tracks/Blind_BT", fileType: "wav")
        #expect(track.url != nil)
    }

    @Test("File source resolves to documents directory URL")
    func fileSourceURL() {
        let track = Track(title: "Song", source: .file(relativePath: "Music/song.mp3"))
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #expect(track.url == documents.appendingPathComponent("Music/song.mp3"))
    }
}

@MainActor
@Suite("MusicLibrary", .serialized)
struct MusicLibraryTests {
    @Test("Importing a file copies it into the music directory and produces a track")
    func importCopiesFile() throws {
        // Create a fake audio file in a temp directory to simulate a picked file.
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let sourceURL = tempDir.appendingPathComponent("Test Song.mp3")
        let payload = Data("fake-audio".utf8)
        try payload.write(to: sourceURL)

        // Clean up any existing destination so the test is repeatable.
        let musicDirectory = try #require(MusicLibrary.musicDirectory)
        let destinationURL = musicDirectory.appendingPathComponent("Test Song.mp3")
        try? FileManager.default.removeItem(at: destinationURL)
        defer { try? FileManager.default.removeItem(at: destinationURL) }

        let tracks = MusicLibrary.importFiles(at: [sourceURL])

        #expect(tracks.count == 1)
        #expect(tracks.first?.title == "Test Song")
        #expect(FileManager.default.fileExists(atPath: destinationURL.path))
        #expect(tracks.first?.url == destinationURL)
    }
}
