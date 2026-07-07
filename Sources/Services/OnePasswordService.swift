import Foundation
import AppKit

// Search 1Password and copy a password to the clipboard via the `op` CLI. The CLI brokers
// auth through the desktop app (Touch ID / app integration), so no secrets are ever passed
// as arguments — `op` resolves the unlocked session itself.
@MainActor
@Observable
final class OnePasswordService {
    static let shared = OnePasswordService()

    struct OPItem: Identifiable, Hashable {
        let id: String
        let title: String
        let subtitle: String
    }

    enum OPStatus {
        case unknown
        case ready
        case needsAuth
        case unavailable
    }

    private(set) var items: [OPItem] = []
    private(set) var status: OPStatus = .unknown
    private(set) var lastCopied: String?
    private(set) var lastError = ""

    private var clearToastTask: Task<Void, Never>?

    private init() {}

    func loadItems() async {
        let result = await Self.run(["item", "list", "--categories", "Login", "--format=json", "--cache"])
        guard result.ok else {
            lastError = (result.err + " " + result.out).trimmingCharacters(in: .whitespacesAndNewlines)
            status = Self.failureStatus(from: result.err + " " + result.out)
            return
        }
        lastError = ""
        guard let data = result.out.data(using: .utf8),
              let listed = try? JSONDecoder().decode([ListedItem].self, from: data) else {
            return
        }
        items = listed.map { listed in
            let subtitle = listed.additionalInformation ?? listed.urls?.first?.href ?? ""
            return OPItem(id: listed.id, title: listed.title, subtitle: subtitle)
        }
        status = .ready
    }

    func filtered(_ query: String) -> [OPItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Array(items.prefix(20)) }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.subtitle.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func copyPassword(_ item: OPItem) async {
        let result = await Self.run(["item", "get", item.id, "--fields", "label=password", "--reveal"])
        guard result.ok else {
            status = Self.failureStatus(from: result.err + " " + result.out)
            return
        }
        let password = result.out.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !password.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(password, forType: .string)
        scheduleClipboardClear(password)

        lastCopied = item.title
        clearToastTask?.cancel()
        clearToastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self?.lastCopied = nil
        }
    }

    // Don't leave a revealed credential on the clipboard indefinitely; clear it if untouched.
    private func scheduleClipboardClear(_ password: String) {
        Task {
            try? await Task.sleep(for: .seconds(90))
            let pasteboard = NSPasteboard.general
            if pasteboard.string(forType: .string) == password {
                pasteboard.clearContents()
            }
        }
    }

    private static func failureStatus(from output: String) -> OPStatus {
        let lower = output.lowercased()
        if lower.contains("not signed in") || lower.contains("authorization")
            || lower.contains("not currently signed in") || lower.contains("session") {
            return .needsAuth
        }
        if lower.contains("no such file") || lower.contains("not found")
            || lower.contains("executable") {
            return .unavailable
        }
        return .needsAuth
    }

    private nonisolated static let opPath: String? = {
        for path in ["/opt/homebrew/bin/op", "/usr/local/bin/op"] where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }()

    // stdout and stderr are kept separate: `op` writes the password (and JSON) to stdout, and
    // notices/errors to stderr — merging them would corrupt a copied secret.
    private nonisolated static func run(_ args: [String]) async -> OPResult {
        guard let opPath else { return OPResult(out: "", err: "not found", ok: false) }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: opPath)
                process.arguments = args
                let outPipe = Pipe()
                let errPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError = errPipe

                let watchdog = DispatchWorkItem { if process.isRunning { process.terminate() } }
                DispatchQueue.global().asyncAfter(deadline: .now() + 60, execute: watchdog)
                do {
                    try process.run()
                    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    watchdog.cancel()
                    let out = String(data: outData, encoding: .utf8) ?? ""
                    let err = String(data: errData, encoding: .utf8) ?? ""
                    continuation.resume(returning: OPResult(out: out, err: err, ok: process.terminationStatus == 0))
                } catch {
                    watchdog.cancel()
                    continuation.resume(returning: OPResult(out: "", err: "not found", ok: false))
                }
            }
        }
    }
}

private struct OPResult {
    let out: String
    let err: String
    let ok: Bool
}

private struct ListedItemURL: Decodable {
    let href: String
}

private struct ListedItem: Decodable {
    let id: String
    let title: String
    let additionalInformation: String?
    let urls: [ListedItemURL]?

    enum CodingKeys: String, CodingKey {
        case id, title, urls
        case additionalInformation = "additional_information"
    }
}
