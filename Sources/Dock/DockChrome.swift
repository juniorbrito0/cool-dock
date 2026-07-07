import SwiftUI

@MainActor
@Observable
final class DockChrome {
    static let shared = DockChrome()
    var minimized = false
    private init() {}
}
