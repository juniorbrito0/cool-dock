import SwiftUI

struct BatteryWidget: DockWidgetView {
    @State private var battery = BatteryService.shared
    init() {}

    var body: some View {
        WidgetTile(widthUnits: WidgetKind.battery.widthUnits) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(tint)
                    .symbolRenderingMode(.hierarchical)
                Text("\(Int(battery.level * 100))%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var symbol: String {
        if battery.isCharging { return "battery.100.bolt" }
        switch battery.level {
        case ..<0.15: return "battery.0"
        case ..<0.4: return "battery.25"
        case ..<0.65: return "battery.50"
        case ..<0.9: return "battery.75"
        default: return "battery.100"
        }
    }

    private var tint: Color {
        if battery.isCharging { return Theme.Color.positive }
        switch battery.level {
        case ..<0.15: return Theme.Color.danger
        case ..<0.3: return Theme.Color.warning
        default: return Theme.Color.accent
        }
    }
}
