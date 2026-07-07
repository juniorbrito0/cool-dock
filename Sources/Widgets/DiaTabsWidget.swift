import SwiftUI

struct DiaTabsWidget: DockWidgetView {
    @State private var dia = DiaService.shared
    @State private var expanded = false
    init() {}

    var body: some View {
        WidgetTile(widthUnits: WidgetKind.diaTabs.widthUnits) {
            Button { expanded.toggle() } label: {
                VStack(spacing: 6) {
                    Image(nsImage: dia.appIcon)
                        .resizable()
                        .frame(width: 30, height: 30)
                    Text(dia.isRunning ? "\(dia.tabs.count)" : "—")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .popover(isPresented: $expanded, arrowEdge: .top) {
            DiaTabsListView(dia: dia) { expanded = false }
        }
        .onAppear { Task { await dia.refresh() } }
    }
}

private struct DiaTabsListView: View {
    let dia: DiaService
    let onPick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(nsImage: dia.appIcon)
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("Dia Tabs")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                Spacer(minLength: 0)
                Text("\(dia.tabs.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(.bottom, 2)

            if !dia.isRunning {
                hint("Dia isn’t running", detail: "Open Dia to see your tabs here.")
            } else if let error = dia.lastError, dia.tabs.isEmpty {
                hint("Can’t read Dia tabs", detail: error)
            } else if dia.tabs.isEmpty {
                hint("No open tabs", detail: nil)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(dia.tabs) { tab in
                            TabRow(tab: tab) {
                                dia.focus(tab)
                                onPick()
                            }
                        }
                    }
                }
                .frame(minHeight: 200, maxHeight: 520)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(width: 320)
    }

    private func hint(_ title: String, detail: String?) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "safari")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Theme.Color.textSecondary)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Color.textPrimary)
            if let detail {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
    }
}

private struct TabRow: View {
    let tab: DiaTab
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "globe")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Color.accent)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(tab.title.isEmpty ? tab.host : tab.title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.Color.textPrimary)
                        .lineLimit(1)
                    Text(tab.host)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.Color.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .frame(height: 40)
            .padding(.horizontal, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hovering ? Theme.Color.tileFillHover : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(tab.url)
    }
}
