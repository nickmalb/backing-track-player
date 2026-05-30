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

    @Test("Update playlist preserves playback when current track still exists")
    func updatePlaylistPreservesCurrentTrack() {
        let player = TrackPlayer(playlist: playlist)
        player.skip()  // now at index 1 ("In The Pines")
        let originalCurrentID = player.currentTrack?.id

        // Remove the first track ("Blind"); current track now moves to index 0.
        var updated = playlist
        updated.tracks.removeFirst()
        player.updatePlaylist(updated)

        #expect(player.currentTrackIndex == 0)
        #expect(player.currentTrack?.id == originalCurrentID)
        #expect(player.currentTrack?.title == "In The Pines")
    }

    @Test("Update playlist loads next track when current track is removed")
    func updatePlaylistLoadsNextOnCurrentRemoval() {
        let player = TrackPlayer(playlist: playlist)
        player.skip()  // now at index 1
        #expect(player.currentTrack?.title == "In The Pines")

        // Remove "In The Pines" (the current track at index 1).
        var updated = playlist
        updated.tracks.remove(at: 1)
        player.updatePlaylist(updated)

        // The track at index 1 in the updated playlist (was "Legacy" at original index 2) should now be current.
        #expect(player.currentTrackIndex == 1)
        #expect(player.currentTrack?.title == "Legacy")
        #expect(player.isPlaying == false)
    }

    @Test("Update playlist clamps index when current track was the last one")
    func updatePlaylistClampsToLast() {
        let player = TrackPlayer(playlist: playlist)
        // Move to the last track.
        for _ in 0..<(playlist.tracks.count - 1) {
            player.skip()
        }
        #expect(player.currentTrackIndex == playlist.tracks.count - 1)

        // Remove the last (current) track.
        var updated = playlist
        updated.tracks.removeLast()
        player.updatePlaylist(updated)

        #expect(player.currentTrackIndex == updated.tracks.count - 1)
        #expect(player.currentTrack?.title == updated.tracks.last?.title)
    }

    @Test("Update playlist with empty tracks unloads the player")
    func updatePlaylistEmptyUnloads() {
        let player = TrackPlayer(playlist: playlist)
        player.play()

        let emptied = Playlist(id: playlist.id, name: playlist.name, tracks: [])
        player.updatePlaylist(emptied)

        #expect(player.currentTrack == nil)
        #expect(player.isPlaying == false)
        #expect(player.duration == 0)
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

@MainActor
@Suite("PlaylistStore", .serialized)
struct PlaylistStoreTests {
    private func makeStore() -> PlaylistStore {
        let suiteName = "PlaylistStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return PlaylistStore(userDefaults: defaults)
    }

    @Test("Default playlist is seeded on first launch")
    func seedsDefaultPlaylist() {
        let store = makeStore()
        #expect(store.playlists.count == 1)
        #expect(store.playlists.first?.name == "Backing Tracks")
    }

    @Test("Adding a playlist appends it with its given name")
    func addPlaylistKeepsName() {
        let store = makeStore()
        let playlist = Playlist(name: "Workout Mix", tracks: [
            Track(title: "Blind", filePath: "Backing Tracks/Blind_BT", fileType: "wav")
        ])
        store.add(playlist)
        #expect(store.playlists.count == 2)
        #expect(store.playlists.last?.name == "Workout Mix")
    }

    @Test("Deleting a playlist removes it")
    func deletePlaylist() {
        let store = makeStore()
        let playlist = Playlist(name: "Extra", tracks: [])
        store.add(playlist)
        store.delete(playlist)
        #expect(store.playlists.contains(where: { $0.id == playlist.id }) == false)
    }

    @Test("Moving a playlist updates the order")
    func movePlaylist() {
        let store = makeStore()
        let a = Playlist(name: "A", tracks: [])
        let b = Playlist(name: "B", tracks: [])
        let c = Playlist(name: "C", tracks: [])
        store.add(a)
        store.add(b)
        store.add(c)
        // Current order: ["Backing Tracks", "A", "B", "C"]
        // Move "A" (index 1) past "C" (insert at index 4)
        store.move(from: IndexSet(integer: 1), to: 4)
        let names = store.playlists.map(\.name)
        #expect(names == ["Backing Tracks", "B", "C", "A"])
    }

    @Test("Renaming a playlist updates its name and preserves order")
    func renamePlaylist() {
        let store = makeStore()
        let original = Playlist(name: "Old Name", tracks: [])
        store.add(original)
        store.renamePlaylist(original, to: "New Name")
        #expect(store.playlists.last?.name == "New Name")
        #expect(store.playlists.last?.id == original.id)
    }

    @Test("Renaming a playlist not in the store has no effect")
    func renameUnknownPlaylistDoesNothing() {
        let store = makeStore()
        let countBefore = store.playlists.count
        let phantom = Playlist(name: "Ghost", tracks: [])
        store.renamePlaylist(phantom, to: "Spectre")
        #expect(store.playlists.count == countBefore)
        #expect(store.playlists.contains(where: { $0.name == "Spectre" }) == false)
    }

    @Test("Rename persists across store instances")
    func renamePersists() {
        let suiteName = "PlaylistStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let firstStore = PlaylistStore(userDefaults: defaults)
        let playlist = Playlist(name: "Original", tracks: [])
        firstStore.add(playlist)
        firstStore.renamePlaylist(playlist, to: "Renamed")

        let secondStore = PlaylistStore(userDefaults: defaults)
        #expect(secondStore.playlists.contains(where: { $0.name == "Renamed" }))
        #expect(secondStore.playlists.contains(where: { $0.name == "Original" }) == false)
    }

    @Test("Adding tracks appends them to the end of the playlist")
    func addTracksAppends() {
        let store = makeStore()
        let playlist = Playlist(name: "List", tracks: [
            Track(title: "First", filePath: "Backing Tracks/Blind_BT", fileType: "wav")
        ])
        store.add(playlist)

        let newTracks = [
            Track(title: "Second", filePath: "Backing Tracks/Legacy_BT", fileType: "wav"),
            Track(title: "Third", filePath: "Backing Tracks/In The Pines_BT", fileType: "wav"),
        ]
        store.addTracks(newTracks, to: playlist.id)

        let stored = store.playlists.first(where: { $0.id == playlist.id })
        #expect(stored?.tracks.map(\.title) == ["First", "Second", "Third"])
    }

    @Test("Deleting tracks removes them from the playlist")
    func deleteTracksRemovesEntries() {
        let store = makeStore()
        let playlist = Playlist(name: "List", tracks: [
            Track(title: "A", filePath: "Backing Tracks/Blind_BT", fileType: "wav"),
            Track(title: "B", filePath: "Backing Tracks/Legacy_BT", fileType: "wav"),
            Track(title: "C", filePath: "Backing Tracks/In The Pines_BT", fileType: "wav"),
        ])
        store.add(playlist)

        store.deleteTracks(at: IndexSet(integer: 1), from: playlist.id)

        let stored = store.playlists.first(where: { $0.id == playlist.id })
        #expect(stored?.tracks.map(\.title) == ["A", "C"])
    }

    @Test("Moving tracks updates their order in the playlist")
    func moveTracksReorders() {
        let store = makeStore()
        let playlist = Playlist(name: "List", tracks: [
            Track(title: "A", filePath: "Backing Tracks/Blind_BT", fileType: "wav"),
            Track(title: "B", filePath: "Backing Tracks/Legacy_BT", fileType: "wav"),
            Track(title: "C", filePath: "Backing Tracks/In The Pines_BT", fileType: "wav"),
        ])
        store.add(playlist)

        // Move "A" (index 0) past "C" (insert at index 3)
        store.moveTracks(from: IndexSet(integer: 0), to: 3, in: playlist.id)

        let stored = store.playlists.first(where: { $0.id == playlist.id })
        #expect(stored?.tracks.map(\.title) == ["B", "C", "A"])
    }

    @Test("Track mutations on unknown playlist have no effect")
    func trackMutationsOnUnknownPlaylistDoNothing() {
        let store = makeStore()
        let countBefore = store.playlists.count
        let unknownID = UUID()
        store.addTracks([Track(title: "X", filePath: "Backing Tracks/Blind_BT", fileType: "wav")], to: unknownID)
        store.deleteTracks(at: IndexSet(integer: 0), from: unknownID)
        store.moveTracks(from: IndexSet(integer: 0), to: 1, in: unknownID)
        #expect(store.playlists.count == countBefore)
    }

    @Test("Changes persist across store instances")
    func persistsAcrossInstances() {
        let suiteName = "PlaylistStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let firstStore = PlaylistStore(userDefaults: defaults)
        firstStore.add(Playlist(name: "Persisted", tracks: []))

        let secondStore = PlaylistStore(userDefaults: defaults)
        #expect(secondStore.playlists.contains(where: { $0.name == "Persisted" }))
    }
}
