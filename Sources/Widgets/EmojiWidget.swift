import SwiftUI

struct EmojiWidget: DockWidgetView {
    @State private var emoji = EmojiService.shared
    init() {}

    var body: some View {
        WidgetTile(widthUnits: WidgetKind.emoji.widthUnits) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(emoji.topFive, id: \.self) { glyph in
                    EmojiButton(glyph: glyph) { emoji.paste(glyph) }
                }
                Spacer(minLength: 0)
                PickerButton { emoji.openPicker() }
            }
        }
    }
}

private struct EmojiButton: View {
    let glyph: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 22))
                .scaleEffect(hovering ? 1.18 : 1)
                .animation(Theme.Motion.spring, value: hovering)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct PickerButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "face.smiling")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Color.textSecondary)
                .opacity(hovering ? 0.9 : 0.4)
                .scaleEffect(hovering ? 1.15 : 1)
                .animation(Theme.Motion.quick, value: hovering)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help("Open emoji picker")
    }
}
