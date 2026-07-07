import Foundation

struct Bookmark: Codable, Identifiable, Hashable {
    let id: UUID
    let urlString: String
    let title: String

    var url: URL? { URL(string: urlString) }
    var host: String { url?.host ?? urlString }
}

@MainActor
@Observable
final class BookmarksService {
    static let shared = BookmarksService()

    private(set) var saved: [Bookmark] = []

    private let defaultsKey = "bookmarks"

    private init() {}

    func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) else { return }
        saved = decoded
    }

    func add(_ url: URL) {
        let urlString = url.absoluteString
        guard !saved.contains(where: { $0.urlString == urlString }) else { return }
        saved.append(Bookmark(id: UUID(), urlString: urlString, title: title(for: url)))
        persist()
    }

    func remove(_ bookmark: Bookmark) {
        saved.removeAll { $0.id == bookmark.id }
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        saved.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(saved) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func title(for url: URL) -> String {
        if let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        let last = url.lastPathComponent
        return last.isEmpty ? url.absoluteString : last
    }
}
