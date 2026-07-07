import SwiftUI

struct QuickActionsWidget: DockWidgetView {
    @State private var actions = QuickActionsService.shared

    init() {}

    var body: some View {
        WidgetTile(widthUnits: WidgetKind.quickActions.widthUnits) {
            VStack(spacing: 6) {
                ForEach(actions.enabledActions) { action in
                    actionButton(symbol: action.symbol, help: action.title) {
                        actions.run(action)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear { actions.load() }
    }

    private func actionButton(symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Color.accent)
                .frame(width: 26, height: 22)
                .background(Theme.Color.accentSoft, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
