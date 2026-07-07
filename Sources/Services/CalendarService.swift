import Foundation
import EventKit

@MainActor
@Observable
final class CalendarService {
    static let shared = CalendarService()

    private(set) var nextEvent: EKEvent?
    private(set) var authorized = false

    private let store = EKEventStore()
    private var task: Task<Void, Never>?

    private init() {}

    func start() {
        guard task == nil else { return }
        refresh()
        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(20))
                self?.refresh()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func refresh() {
        let status = EKEventStore.authorizationStatus(for: .event)
        authorized = status == .fullAccess || status == .authorized
        guard authorized else { nextEvent = nil; return }
        let now = Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        let events = store.events(matching: predicate)
            .filter { !$0.isAllDay && ($0.endDate ?? now) > now }
            .sorted { ($0.startDate ?? now) < ($1.startDate ?? now) }
        nextEvent = events.first
    }
}
