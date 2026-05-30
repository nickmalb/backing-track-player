import SwiftUI

struct MainView: View {
    var playlistStore: PlaylistStore
    var trackPlayer: TrackPlayer

    @State private var selectedPlaylistID: UUID?
    @State private var showingMusicPicker = false
    @State private var showingPlaylistMenu = false

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            Group {
                if isLandscape {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
        }
        .onChange(of: selectedPlaylistID) { _, newID in
            if let newID, let playlist = playlistStore.playlists.first(where: { $0.id == newID }) {
                trackPlayer.loadPlaylist(playlist)
                showingPlaylistMenu = false
            }
        }
        .task {
            if selectedPlaylistID == nil, let first = playlistStore.playlists.first {
                selectedPlaylistID = first.id
            }
        }
    }

    private var landscapeLayout: some View {
        NavigationSplitView {
            playlistList
        } detail: {
            PlayerView(trackPlayer: trackPlayer)
        }
    }

    private var portraitLayout: some View {
        NavigationStack {
            PlayerView(trackPlayer: trackPlayer)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingPlaylistMenu = true
                        } label: {
                            Image(systemName: "sidebar.left")
                        }
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingPlaylistMenu) {
            NavigationStack {
                playlistList
            }
        }
    }

    @ViewBuilder
    private var playlistList: some View {
        List(selection: $selectedPlaylistID) {
            ForEach(playlistStore.playlists) { playlist in
                Text(playlist.name).tag(playlist.id)
            }
            .onDelete(perform: deletePlaylists)
        }
        .navigationTitle("Playlists")
        .toolbar {
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
                let playlist = Playlist(
                    name: "Playlist \(playlistStore.playlists.count + 1)",
                    tracks: tracks
                )
                playlistStore.add(playlist)
                selectedPlaylistID = playlist.id
            } onCancel: {
                showingMusicPicker = false
            }
        }
    }

    private func deletePlaylists(at offsets: IndexSet) {
        for index in offsets {
            let playlist = playlistStore.playlists[index]
            playlistStore.delete(playlist)
        }
    }
}
