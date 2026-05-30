import Foundation

struct Track: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let source: Source

    init(id: UUID = UUID(), title: String, source: Source) {
        self.id = id
        self.title = title
        self.source = source
    }

    init(title: String, filePath: String, fileType: String) {
        self.init(title: title, source: .bundle(filePath: filePath, fileType: fileType))
    }

    enum Source: Codable, Hashable {
        case bundle(filePath: String, fileType: String)
        case file(relativePath: String)
    }

    var url: URL? {
        switch source {
        case let .bundle(filePath, fileType):
            return Bundle.main.url(forResource: filePath, withExtension: fileType)
        case let .file(relativePath):
            guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            return documents.appendingPathComponent(relativePath)
        }
    }
}
