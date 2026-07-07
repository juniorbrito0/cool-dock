import SwiftUI

// Shared chrome for every widget: rounded glass card, hover lift, consistent padding.
struct WidgetTile<Content: View>: View {
    var widthUnits: CGFloat = 1
    @ViewBuilder var content: Content

    @State private var hovering = false

    private var width: CGFloat { Theme.Size.tile * widthUnits + Theme.Spacing.md * (widthUnits - 1) }

    var body: some View {
        content
            .frame(width: width, height: Theme.Size.tile, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.md)
            .background(
                // Each tile gets its own frosted backing so it reads as a solid card against the
                // (much more transparent) bar frame, plus a white wash for definition on hover.
                ZStack {
                    VisualEffectView(material: .hudWindow)
                    RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                        .fill(hovering ? Theme.Color.tileFillHover : Theme.Color.tileFill)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.tile, style: .continuous)
                    .strokeBorder(Theme.Color.tileStroke, lineWidth: 1)
            )
            .scaleEffect(hovering ? 1.04 : 1)
            .animation(Theme.Motion.spring, value: hovering)
            .onHover { hovering = $0 }
    }
}

// Compact label used inside tiles: a glyph over/next to a value.
struct TileGlyph: View {
    let symbol: String
    var tint: Color = Theme.Color.textSecondary

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: Theme.Size.iconGlyph, weight: .medium))
            .foregroundStyle(tint)
            .symbolRenderingMode(.hierarchical)
    }
}
