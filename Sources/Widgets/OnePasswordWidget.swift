import SwiftUI

struct OnePasswordWidget: DockWidgetView {
    @State private var service = OnePasswordService.shared
    @State private var expanded = false
    @State private var query = ""
    init() {}

    var body: some View {
        Button { expanded.toggle() } label: {
            WidgetTile(widthUnits: WidgetKind.onePassword.widthUnits) {
                VStack(spacing: Theme.Spacing.xs) {
                    TileGlyph(symbol: "key", tint: Theme.Color.accent)
                    Text("1Password")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.Color.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $expanded, arrowEdge: .top) {
            OnePasswordSearchView(service: service, query: $query)
                .task { await service.loadItems() }
        }
    }
}

private struct OnePasswordSearchView: View {
    let service: OnePasswordService
    @Binding var query: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Color.textSecondary)
                TextField("Search 1Password…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                    .fill(Theme.Color.tileFill)
            )

            content

            if let copied = service.lastCopied {
                Label("Copied ✓ \(copied)", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Color.positive)
                    .lineLimit(1)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(width: 260)
    }

    @ViewBuilder
    private var content: some View {
        switch service.status {
        case .needsAuth:
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Approve Dock+ in the 1Password CLI prompt, then retry")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Color.textSecondary)
                if !service.lastError.isEmpty {
                    Text(service.lastError)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Color.danger)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
                Button("Retry") { Task { await service.loadItems() } }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.Color.accent)
            }
        case .unavailable:
            VStack(alignment: .leading, spacing: 6) {
                Text("1Password CLI unavailable")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Color.textSecondary)
                if !service.lastError.isEmpty {
                    Text(service.lastError)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Color.danger)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
            }
        default:
            resultsList
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(service.filtered(query)) { item in
                    ResultRow(item: item) {
                        Task { await service.copyPassword(item) }
                    }
                }
            }
        }
        .frame(height: 220)
    }
}

private struct ResultRow: View {
    let item: OnePasswordService.OPItem
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: item.subtitle.isEmpty ? "lock.fill" : "globe")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Color.textSecondary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                        .lineLimit(1)
                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Color.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Spacing.md, style: .continuous)
                    .fill(hovering ? Theme.Color.tileFillHover : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
