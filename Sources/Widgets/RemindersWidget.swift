import SwiftUI

struct RemindersWidget: DockWidgetView {
    @State private var reminders = RemindersService.shared
    @State private var expanded = false
    init() {}

    var body: some View {
        WidgetTile(widthUnits: WidgetKind.reminders.widthUnits) {
            Button { expanded.toggle() } label: {
                VStack(spacing: 6) {
                    Image(systemName: WidgetKind.reminders.symbol)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.Color.textSecondary)
                        .symbolRenderingMode(.hierarchical)
                    Text("\(reminders.reminders.count)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .popover(isPresented: $expanded, arrowEdge: .top) {
            RemindersListView(reminders: reminders)
        }
    }
}

private struct RemindersListView: View {
    @Bindable var reminders: RemindersService
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if reminders.authorized {
                scopePicker
                addField
                if reminders.reminders.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            ForEach(reminders.reminders) { item in
                                ReminderRow(item: item,
                                            onComplete: { reminders.complete(item) },
                                            onReschedule: { reminders.reschedule(item, to: $0) })
                            }
                        }
                    }
                    .frame(maxHeight: 260)
                }
            } else {
                accessPrompt
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(width: 280)
    }

    private var scopePicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Menu {
                Button("Today") { reminders.scope = .today }
                Button("All Lists") { reminders.scope = .all }
                if !reminders.lists.isEmpty {
                    Divider()
                    ForEach(reminders.lists) { list in
                        Button(list.title) { reminders.scope = .list(list.id) }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(scopeLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            Spacer(minLength: 0)
        }
        .padding(.bottom, 2)
    }

    private var scopeLabel: String {
        switch reminders.scope {
        case .today: "Today"
        case .all: "All Lists"
        case .list(let id): reminders.lists.first { $0.id == id }?.title ?? "List"
        }
    }

    private var addField: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.Color.accent)
            TextField("New reminder", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit(submit)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                .fill(Theme.Color.tileFill)
        )
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Theme.Color.positive)
                .symbolRenderingMode(.hierarchical)
            Text("All clear")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
    }

    private var accessPrompt: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checklist")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Theme.Color.textSecondary)
                .symbolRenderingMode(.hierarchical)
            Text("Reminders access needed")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Color.textPrimary)
            Button("Enable Access") { PermissionsService.shared.requestReminders() }
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
    }

    private func submit() {
        reminders.add(title: draft, due: nil)
        draft = ""
    }
}

private struct ReminderRow: View {
    let item: ReminderItem
    let onComplete: () -> Void
    let onReschedule: (Date) -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button(action: onComplete) {
                Image(systemName: "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Color.accent)
            }
            .buttonStyle(.plain)
            .help("Complete")

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                    .lineLimit(1)
                if let due = item.due {
                    Text(due, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(item.isOverdue ? Theme.Color.danger : Theme.Color.textSecondary)
                }
            }
            Spacer(minLength: 0)

            if hovering {
                Menu {
                    Button("Today") { onReschedule(Reschedule.today()) }
                    Button("Tomorrow") { onReschedule(Reschedule.tomorrow()) }
                    Button("Next Week") { onReschedule(Reschedule.nextWeek()) }
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Reschedule")
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                .fill(hovering ? Theme.Color.tileFillHover : Color.clear)
        )
        .onHover { hovering = $0 }
    }
}

private enum Reschedule {
    static func today() -> Date { at(hour: 17, dayOffset: 0) }
    static func tomorrow() -> Date { at(hour: 9, dayOffset: 1) }

    static func nextWeek() -> Date {
        let calendar = Calendar.current
        let base = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: base) ?? base
    }

    private static func at(hour: Int, dayOffset: Int) -> Date {
        let calendar = Calendar.current
        let base = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
    }
}
