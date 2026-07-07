import SwiftUI

struct ClockWeatherWidget: DockWidgetView {
    @State private var weather = WeatherService.shared
    init() {}

    var body: some View {
        WidgetTile(widthUnits: WidgetKind.clockWeather.widthUnits) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let date = context.date
                HStack(spacing: Theme.Spacing.xs) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(date, format: .dateTime.hour().minute())
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Theme.Color.textPrimary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text(date, format: .dateTime.weekday(.abbreviated).day())
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer(minLength: 2)
                    VStack(alignment: .trailing, spacing: 0) {
                        HStack(spacing: 3) {
                            Image(systemName: weather.symbol)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.Color.accent)
                                .symbolRenderingMode(.hierarchical)
                            Text(weather.temperature.map { "\($0)°" } ?? "—")
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.Color.textPrimary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        Text(weather.locationName.isEmpty ? weather.summary : weather.locationName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Theme.Color.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
