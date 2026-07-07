import SwiftUI
import AppKit

struct FavoriteApp: Identifiable, Hashable {
    let id: String        // bundle path
    let name: String
    let url: URL
    let icon: NSImage
}

@MainActor
@Observable
final class AppsService {
    static let shared = AppsService()

    private(set) var favorites: [FavoriteApp] = []

    private let defaultsKey = "favoriteAppPaths"
    private let seedBundleIDs = [
        "com.apple.Safari",
        "com.apple.mail",
        "com.apple.Notes",
        "com.apple.MobileSMS",
        "com.apple.Music",
        "com.apple.systempreferences"
    ]

    private init() {}

    func load() {
        let stored = UserDefaults.standard.stringArray(forKey: defaultsKey)
        let paths = stored ?? seedPaths()
        favorites = paths.compactMap(makeApp)
        if stored == nil { persist() }
    }

    func launch(_ app: FavoriteApp) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: app.url, configuration: config)
    }

    func add(_ url: URL) {
        guard !favorites.contains(where: { $0.url == url }), let app = makeApp(path: url.path) else { return }
        favorites.append(app)
        persist()
    }

    func remove(_ app: FavoriteApp) {
        favorites.removeAll { $0.id == app.id }
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(favorites.map(\.url.path), forKey: defaultsKey)
    }

    private func seedPaths() -> [String] {
        seedBundleIDs.compactMap {
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0)?.path
        }
    }

    private func makeApp(path: String) -> FavoriteApp? {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        let name = FileManager.default.displayName(atPath: path).replacingOccurrences(of: ".app", with: "")
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 40, height: 40)
        return FavoriteApp(id: path, name: name, url: url, icon: icon)
    }
}
