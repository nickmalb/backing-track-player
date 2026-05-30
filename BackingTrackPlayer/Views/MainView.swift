import SwiftUI

struct MainView: View {
    var playlistStore: PlaylistStore
    var trackPlayer: TrackPlayer

    @State private var selectedPlaylistID: UUID?
    @State private var showingNamePrompt = false
    @State private var newPlaylistName = ""
    @State private var pendingPlaylistName: String?
    @State private var showingMusicPicker = false
    @State private var showingPlaylistMenu = false
    @State private var renamingPlaylist: Playlist?
    @State private var renamePlaylistName = ""
    @State private var editingPlaylist: Playlist?

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
        .alert("New Playlist", isPresented: $showingNamePrompt) {
            TextField("Playlist name", text: $newPlaylistName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) {
                pendingPlaylistName = nil
            }
            Button("Next") {
                let trimmed = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
                pendingPlaylistName = trimmed.isEmpty
                    ? "Playlist \(playlistStore.playlists.count + 1)"
                    : trimmed
                let wasShowingMenu = showingPlaylistMenu
                showingPlaylistMenu = false
                if wasShowingMenu {
                    // Wait for the playlist menu sheet to dismiss before presenting the picker.
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(400))
                        showingMusicPicker = true
                    }
                } else {
                    showingMusicPicker = true
                }
            }
        } message: {
            Text("Enter a name for the new playlist.")
        }
        .alert("Rename Playlist", isPresented: Binding(
            get: { renamingPlaylist != nil },
            set: { if !$0 { renamingPlaylist = nil } }
        )) {
            TextField("Name", text: $renamePlaylistName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let playlist = renamingPlaylist {
                    let trimmed = renamePlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        playlistStore.renamePlaylist(playlist, to: trimmed)
                    }
                }
            }
        } message: {
            Text("Enter a new name for the playlist.")
        }
        .sheet(isPresented: $showingMusicPicker) {
            MusicPicker { tracks in
                showingMusicPicker = false
                guard !tracks.isEmpty, let name = pendingPlaylistName else {
                    pendingPlaylistName = nil
                    return
                }
                let playlist = Playlist(name: name, tracks: tracks)
                playlistStore.add(playlist)
                selectedPlaylistID = playlist.id
                pendingPlaylistName = nil
            } onCancel: {
                showingMusicPicker = false
                pendingPlaylistName = nil
            }
        }
        .sheet(item: $editingPlaylist) { playlist in
            NavigationStack {
                PlaylistEditView(
                    playlistID: playlist.id,
                    playlistStore: playlistStore,
                    trackPlayer: trackPlayer,
                    onPlaylistEmptied: {
                        selectedPlaylistID = nil
                        editingPlaylist = nil
                    }
                )
            }
        }
    }

    private func openEditor(for playlist: Playlist) {
        let wasShowingMenu = showingPlaylistMenu
        showingPlaylistMenu = false
        if wasShowingMenu {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                editingPlaylist = playlist
            }
        } else {
            editingPlaylist = playlist
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
                Text(playlist.name)
                    .tag(playlist.id)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            renamePlaylistName = playlist.name
                            renamingPlaylist = playlist
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.blue)

                        Button {
                            openEditor(for: playlist)
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }
                        .tint(.indigo)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            playlistStore.delete(playlist)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            renamePlaylistName = playlist.name
                            renamingPlaylist = playlist
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Button {
                            openEditor(for: playlist)
                        } label: {
                            Label("Edit", systemImage: "square.and.pencil")
                        }

                        Button(role: .destructive) {
                            playlistStore.delete(playlist)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onMove(perform: movePlaylists)
        }
        .navigationTitle("Playlists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newPlaylistName = ""
                    showingNamePrompt = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func movePlaylists(from source: IndexSet, to destination: Int) {
        playlistStore.move(from: source, to: destination)
    }
}
