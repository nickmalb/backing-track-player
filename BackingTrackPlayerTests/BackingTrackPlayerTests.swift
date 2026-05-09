import Testing
@testable import BackingTrackPlayer

@MainActor
@Suite("TrackPlayer", .serialized)
struct TrackPlayerTests {
    let tracks = [
        Track(title: "Blind", filePath: "Backing Tracks/Blind_BT", fileType: "wav"),
        Track(title: "In The Pines", filePath: "Backing Tracks/In The Pines_BT", fileType: "wav"),
        Track(title: "Legacy", filePath: "Backing Tracks/Legacy_BT", fileType: "wav"),
        Track(title: "Sense Control", filePath: "Backing Tracks/Sense Control_BT", fileType: "wav"),
        Track(title: "When Morning Came", filePath: "Backing Tracks/When Morning Came_BT", fileType: "wav"),
    ]

    @Test("Tracks are ordered alphabetically matching folder order")
    func trackOrder() {
        let player = TrackPlayer(tracks: tracks)
        #expect(player.tracks[0].title == "Blind")
        #expect(player.tracks[1].title == "In The Pines")
        #expect(player.tracks[2].title == "Legacy")
        #expect(player.tracks[3].title == "Sense Control")
        #expect(player.tracks[4].title == "When Morning Came")
    }

    @Test("First track is loaded on init")
    func firstTrackLoadedOnInit() {
        let player = TrackPlayer(tracks: tracks)
        #expect(player.currentTrackIndex == 0)
        #expect(player.currentTrack.title == "Blind")
        #expect(player.isPlaying == false)
    }

    @Test("Play starts playback")
    func playStartsPlayback() {
        let player = TrackPlayer(tracks: tracks)
        player.play()
        #expect(player.isPlaying == true)
    }

    @Test("Stop stops playback")
    func stopStopsPlayback() {
        let player = TrackPlayer(tracks: tracks)
        player.play()
        player.stop()
        #expect(player.isPlaying == false)
    }

    @Test("Play after stop resumes without changing track")
    func playAfterStop() {
        let player = TrackPlayer(tracks: tracks)
        player.play()
        player.stop()
        player.play()
        #expect(player.isPlaying == true)
        #expect(player.currentTrackIndex == 0)
    }

    @Test("Rewind stops playback and resets to beginning")
    func rewindResetsToBeginning() {
        let player = TrackPlayer(tracks: tracks)
        player.play()
        player.rewind()
        #expect(player.isPlaying == false)
        #expect(player.currentTime == 0)
        #expect(player.currentTrackIndex == 0)
    }

    @Test("Rewind at beginning loads previous track")
    func rewindAtBeginningLoadsPreviousTrack() {
        let player = TrackPlayer(tracks: tracks)
        player.skip()
        #expect(player.currentTrackIndex == 1)

        // Position is 0 after skip (just loaded), so rewind goes to previous track
        player.rewind()
        #expect(player.currentTrackIndex == 0)
        #expect(player.currentTrack.title == "Blind")
    }

    @Test("Rewind at beginning of first track stays on first track")
    func rewindAtFirstTrackStays() {
        let player = TrackPlayer(tracks: tracks)
        player.rewind()
        player.rewind()
        #expect(player.currentTrackIndex == 0)
        #expect(player.currentTrack.title == "Blind")
    }

    @Test("Skip advances to next track without starting playback")
    func skipAdvancesWithoutPlaying() {
        let player = TrackPlayer(tracks: tracks)
        player.skip()
        #expect(player.currentTrackIndex == 1)
        #expect(player.currentTrack.title == "In The Pines")
        #expect(player.isPlaying == false)
    }

    @Test("Skip stops playback if playing")
    func skipStopsPlayback() {
        let player = TrackPlayer(tracks: tracks)
        player.play()
        player.skip()
        #expect(player.isPlaying == false)
        #expect(player.currentTrackIndex == 1)
    }

    @Test("Skip wraps around to first track after last")
    func skipWrapsAround() {
        let player = TrackPlayer(tracks: tracks)
        for _ in 0..<tracks.count {
            player.skip()
        }
        #expect(player.currentTrackIndex == 0)
        #expect(player.currentTrack.title == "Blind")
    }

    @Test("Skip through all tracks visits each in order")
    func skipThroughAllTracks() {
        let player = TrackPlayer(tracks: tracks)
        for i in 0..<tracks.count {
            #expect(player.currentTrack.title == tracks[i].title)
            player.skip()
        }
    }

    @Test("Track has positive duration after loading")
    func trackHasDuration() {
        let player = TrackPlayer(tracks: tracks)
        #expect(player.duration > 0)
    }

    @Test("Current time resets when loading new track via skip")
    func currentTimeResetsOnSkip() {
        let player = TrackPlayer(tracks: tracks)
        player.play()
        player.skip()
        #expect(player.currentTime == 0)
    }
}
