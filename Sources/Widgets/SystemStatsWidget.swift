import SwiftUI

struct SystemStatsWidget: DockWidgetView {
    @State private var stats = SystemStatsService.shared
    init() {}

    var body: some View {
        WidgetTile(widthUnits: WidgetKind.systemStats.widthUnits) {
            HStack(spacing: Theme.Spacing.lg) {
                gauge(value: stats.cpuUsage, label: "CPU", symbol: "cpu")
                gauge(value: stats.memoryUsed, label: "RAM", symbol: "memorychip")
            }
        }
    }

    private func gauge(value: Double, label: String, symbol: String) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Theme.Color.tileStroke, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: max(0.02, value))
                    .stroke(tint(for: value), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Motion.spring, value: value)
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .frame(width: 30, height: 30)
            Text("\(Int(value * 100))%")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    private func tint(for value: Double) -> Color {
        switch value {
        case ..<0.6: Theme.Color.accent
        case ..<0.85: Theme.Color.warning
        default: Theme.Color.danger
        }
    }
}
