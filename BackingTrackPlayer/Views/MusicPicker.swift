import SwiftUI
import UniformTypeIdentifiers

struct MusicPicker: UIViewControllerRepresentable {
    static let supportedTypes: [UTType] = [
        .audio,
        .mp3,
        .wav,
        .mpeg4Audio,
        .aiff
    ]

    let onPick: ([Track]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: Self.supportedTypes, asCopy: true)
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
            let audioURLs = urls.filter { Self.isAudioFile(at: $0) }
            let tracks = MusicLibrary.importFiles(at: audioURLs)
            onPick(tracks)
        }

        private static func isAudioFile(at url: URL) -> Bool {
            guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                return false
            }
            return type.conforms(to: .audio)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}
