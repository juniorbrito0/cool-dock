import SwiftUI
import AppKit
import QuickLookThumbnailing

struct FavoriteFolder: Identifiable, Hashable {
    let id: String        // folder path
    let name: String
    let url: URL
    let icon: NSImage
}

struct FolderFile: Identifiable, Hashable {
    let id: String        // file path
    let name: String
    let url: URL
}

@MainActor
@Observable
final class FoldersService {
    static let shared = FoldersService()

    private(set) var folders: [FavoriteFolder] = []

    private let defaultsKey = "favoriteFolderPaths"
    private let fileLimit = 40
    private var thumbnails: [String: NSImage] = [:]

    private init() {}

    func load() {
        let stored = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        folders = stored.compactMap(makeFolder)
    }

    func add(_ url: URL) {
        guard !folders.contains(where: { $0.url == url }), let folder = makeFolder(path: url.path) else { return }
        folders.append(folder)
        persist()
    }

    func remove(_ folder: FavoriteFolder) {
        folders.removeAll { $0.id == folder.id }
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        folders.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    func files(in folder: FavoriteFolder) -> [FolderFile] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: folder.url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        return urls
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .prefix(fileLimit)
            .map { FolderFile(id: $0.path, name: FileManager.default.displayName(atPath: $0.path), url: $0) }
    }

    func open(_ file: FolderFile) {
        NSWorkspace.shared.open(file.url)
    }

    func reveal(_ folder: FavoriteFolder) {
        NSWorkspace.shared.open(folder.url)
    }

    func thumbnail(for file: FolderFile) async -> NSImage {
        if let cached = thumbnails[file.id] { return cached }
        let image = await generateThumbnail(for: file.url) ?? fallbackIcon(for: file.id)
        thumbnails[file.id] = image
        return image
    }

    private func generateThumbnail(for url: URL) async -> NSImage? {
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 40, height: 40),
            scale: scale,
            representationTypes: .all
        )
        do {
            let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            return representation.nsImage
        } catch {
            return nil
        }
    }

    private func fallbackIcon(for path: String) -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 40, height: 40)
        return icon
    }

    private func persist() {
        UserDefaults.standard.set(folders.map(\.url.path), forKey: defaultsKey)
    }

    private func makeFolder(path: String) -> FavoriteFolder? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else { return nil }
        let url = URL(fileURLWithPath: path)
        let name = FileManager.default.displayName(atPath: path)
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 40, height: 40)
        return FavoriteFolder(id: path, name: name, url: url, icon: icon)
    }
}
