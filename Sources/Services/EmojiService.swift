import SwiftUI
import AppKit

@MainActor
@Observable
final class EmojiService {
    static let shared = EmojiService()

    private(set) var topFive: [String] = []

    private let defaultsKey = "emojiUsageCounts"
    private let seedCounts: [String: Int] = ["😂": 1, "❤️": 1, "👍": 1, "🔥": 1, "🙏": 1]

    private init() {}

    func load() {
        if counts().isEmpty { persist(seedCounts) }
        refresh()
    }

    func record(_ emoji: String) {
        var current = counts()
        current[emoji, default: 0] += 1
        persist(current)
        refresh()
    }

    func paste(_ emoji: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(emoji, forType: .string)
        record(emoji)
        guard AXIsProcessTrusted() else { return }
        synthesizeCommandV()
    }

    // Opens the system Emoji & Symbols popover in the frontmost app via its Ctrl+Cmd+Space
    // shortcut (a background app's orderFrontCharacterPalette targets nothing useful).
    func openPicker() {
        guard AXIsProcessTrusted() else {
            NSApp.orderFrontCharacterPalette(nil)
            return
        }
        synthesizeKey(49, flags: [.maskCommand, .maskControl])   // Space
    }

    private func synthesizeCommandV() {
        synthesizeKey(9, flags: .maskCommand)   // V
    }

    private func synthesizeKey(_ keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else { return }
        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func counts() -> [String: Int] {
        UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Int] ?? [:]
    }

    private func persist(_ counts: [String: Int]) {
        UserDefaults.standard.set(counts, forKey: defaultsKey)
    }

    private func refresh() {
        topFive = counts()
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map(\.key)
    }
}
