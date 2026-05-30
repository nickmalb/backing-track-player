import AVFoundation
import Observation

@Observable
@MainActor
final class TrackPlayer {
    private(set) var playlist: Playlist
    private(set) var currentTrackIndex: Int = 0
    private(set) var isPlaying: Bool = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var delegate: AudioDelegate?
    private var progressTimer: Timer?

    var tracks: [Track] { playlist.tracks }
    var currentTrack: Track? {
        tracks.indices.contains(currentTrackIndex) ? tracks[currentTrackIndex] : nil
    }

    init(playlist: Playlist) {
        self.playlist = playlist
        loadCurrentTrack()
    }

    func loadPlaylist(_ playlist: Playlist) {
        player?.stop()
        isPlaying = false
        stopProgressTimer()
        self.playlist = playlist
        currentTrackIndex = 0
        loadCurrentTrack()
    }

    func play() {
        player?.play()
        isPlaying = true
        startProgressTimer()
    }

    func stop() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
        currentTime = player?.currentTime ?? 0
    }

    func rewind() {
        guard !tracks.isEmpty else { return }
        let atStart = (player?.currentTime ?? 0) == 0
        player?.pause()
        isPlaying = false
        stopProgressTimer()
        if atStart && currentTrackIndex > 0 {
            currentTrackIndex -= 1
            loadCurrentTrack()
        } else {
            player?.currentTime = 0
            currentTime = 0
        }
    }

    func skip() {
        guard !tracks.isEmpty else { return }
        player?.stop()
        isPlaying = false
        stopProgressTimer()
        advanceToNextTrack()
    }

    private func advanceToNextTrack() {
        currentTrackIndex = (currentTrackIndex + 1) % tracks.count
        loadCurrentTrack()
    }

    private func loadCurrentTrack() {
        guard let track = currentTrack, let url = track.url else {
            player = nil
            duration = 0
            currentTime = 0
            return
        }
        player = try? AVAudioPlayer(contentsOf: url)
        delegate = AudioDelegate { [weak self] in
            self?.handlePlaybackFinished()
        }
        player?.delegate = delegate
        player?.prepareToPlay()
        duration = player?.duration ?? 0
        currentTime = 0
    }

    private func handlePlaybackFinished() {
        isPlaying = false
        stopProgressTimer()
        advanceToNextTrack()
    }

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.currentTime = self?.player?.currentTime ?? 0
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

private final class AudioDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: @MainActor () -> Void

    init(onFinish: @escaping @MainActor () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.onFinish()
        }
    }
}
