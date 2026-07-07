# Cool Dock

<!-- bootstrapped: v1 -->

A native macOS app that adds a **floating second Dock with live widgets** beside the system Dock — a clone of the concept behind [dock.cool](https://www.dock.cool) (Cooldock). Personal project.

## Type & stack
- **macOS-only SwiftUI app**, deployment target macOS 14 (Sonoma).
- **XcodeGen** (`project.yml`) — the `.xcodeproj` is generated and git-ignored. Never hand-edit it.
- Swift 6, strict concurrency (`complete`). `@Observable` services, async/await, `@MainActor` for UI/state.
- Bundle ID `ai.brito.cooldock`, team `YDC59VMG55`. Agent app (`LSUIElement`), no Dock icon; controlled from a `MenuBarExtra`.
- Not sandboxed (needs `NSWorkspace` app launch, mach/IOKit system stats) — fine for a personal build.

## Architecture
- `Sources/App` — `@main` app, `AppDelegate` (starts services + the dock panel), MenuBarExtra, Settings window.
- `Sources/Dock` — `DockWindowController` (borderless non-activating `NSPanel` floating above the system Dock, all-Spaces) hosting `DockView` (the glass bar).
- `Sources/Widgets` — one file per widget; all conform to `DockWidgetView` and are wired in `WidgetRegistry`. **Adding a widget = new `WidgetKind` case + view + registry line.**
- `Sources/Services` — `@MainActor @Observable` singletons polling live data (system stats via mach, battery via IOKit, weather via CoreLocation + Open-Meteo, calendar via EventKit, apps via NSWorkspace).
- `Sources/DesignSystem` — `Theme` tokens (palette/spacing/radius/motion) + `VisualEffectView`. Build screens from tokens; never hardcode values that belong in the system.
- `Sources/Settings` — `DockSettings` (persisted enabled widgets + edge) and the settings UI.

## Keyless by design
Weather uses the free **Open-Meteo** API (no key) + CoreLocation. System stats/battery read the kernel directly. No accounts, no API keys for the core widgets.

## Conventions
The global config at `~/.claude/` applies. Verify with `xcodegen generate` → `swiftlint --quiet` (0 violations) → `xcodebuild … build` (BUILD SUCCEEDED) → launch + `screencapture` proof. Append to `docs/WORKLOG.md` after each substantive change.

@include .claude/rules/apple-app-development.md
@include .claude/rules/design.md
