import SwiftUI
import UniformTypeIdentifiers

struct MusicPicker: UIViewControllerRepresentable {
    let onPick: ([Track]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    @MainActor
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([Track]) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping ([Track]) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let tracks = MusicLibrary.importFiles(at: urls)
            onPick(tracks)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}

enum MusicLibrary {
    static let musicDirectoryName = "Music"

    static var musicDirectory: URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let directory = documents.appendingPathComponent(musicDirectoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func importFiles(at sourceURLs: [URL]) -> [Track] {
        guard let musicDirectory else { return [] }
        var tracks: [Track] = []
        for sourceURL in sourceURLs {
            let filename = sourceURL.lastPathComponent
            let destinationURL = musicDirectory.appendingPathComponent(filename)
            if !FileManager.default.fileExists(atPath: destinationURL.path) {
                do {
                    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                } catch {
                    continue
                }
            }
            let title = sourceURL.deletingPathExtension().lastPathComponent
            let relativePath = "\(musicDirectoryName)/\(filename)"
            tracks.append(Track(title: title, source: .file(relativePath: relativePath)))
        }
        return tracks
    }
}
