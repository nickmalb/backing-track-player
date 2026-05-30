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
