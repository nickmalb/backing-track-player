import Foundation

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
