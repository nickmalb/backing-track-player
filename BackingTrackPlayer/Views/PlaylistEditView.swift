import SwiftUI

struct PlaylistEditView: View {
    let playlistID: UUID
    var playlistStore: PlaylistStore
    var trackPlayer: TrackPlayer
    var onPlaylistEmptied: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingMusicPicker = false

    private var playlist: Playlist? {
        playlistStore.playlists.first(where: { $0.id == playlistID })
    }

    var body: some View {
        List {
            if let playlist {
                ForEach(playlist.tracks) { track in
                    Text(track.title)
                }
                .onMove(perform: moveTracks)
                .onDelete(perform: deleteTracks)
            }
        }
        .navigationTitle(playlist?.name ?? "Playlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingMusicPicker = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingMusicPicker) {
            MusicPicker { tracks in
                showingMusicPicker = false
                guard !tracks.isEmpty else { return }
                playlistStore.addTracks(tracks, to: playlistID)
                syncPlayerIfCurrent()
            } onCancel: {
                showingMusicPicker = false
            }
        }
    }

    private func deleteTracks(at offsets: IndexSet) {
        playlistStore.deleteTracks(at: offsets, from: playlistID)
        syncPlayerIfCurrent()
    }

    private func moveTracks(from source: IndexSet, to destination: Int) {
        playlistStore.moveTracks(from: source, to: destination, in: playlistID)
        syncPlayerIfCurrent()
    }

    private func syncPlayerIfCurrent() {
        guard trackPlayer.playlist.id == playlistID else { return }
        guard let updated = playlistStore.playlists.first(where: { $0.id == playlistID }) else { return }
        trackPlayer.updatePlaylist(updated)
        if updated.tracks.isEmpty {
            onPlaylistEmptied()
        }
    }
}
