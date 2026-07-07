# Apple App Development

Junior ships native Apple apps regularly. This is the house style and the hard-won submission playbook. Load this rule for any iOS / iPadOS / macOS project. Before building, study a shipped sibling (MyDay, whatnext, Aqua Monitor, Cash Flow Ern) and match its conventions exactly rather than introducing your own.

## Stack & conventions
- **XcodeGen** (`project.yml`) — the `.xcodeproj` is generated and git-ignored. Never hand-edit it.
- SwiftUI multiplatform, single target (iOS 17 / iPadOS / macOS 14), Swift 6 strict concurrency. `@Observable` (not `ObservableObject`), async/await, Sendable value types.
- SwiftData + CloudKit (private DB) for sync; StoreKit 2 for IAP; Swift Charts; SwiftLint; fastlane.
- **Bundle prefix `ai.brito.*`. Every app gets its own unique bundle ID** (e.g. `ai.brito.myday`, `ai.brito.aquamonitor`). Team `YDC59VMG55`.
- Per-app scaffold: `.claude/agents/` (swift-build-runner, swift-test-engineer, swiftui-designer, swiftui-ui-verifier, app-store-release) + hooks (`protect-files.sh`, `swift-format-lint.sh`), `CLAUDE.md`, `ROADMAP.md`, `docs/WORKLOG.md` (append after each substantive change).

## Product defaults Junior likes
- Freemium: a one-time lifetime unlock and/or monthly+yearly subscription, with a usable free tier.
- Localize from the start — EN + PT-BR minimum (markets CA/US/BR), ES where it fits. Identical string-key sets across languages.
- **Dark mode is mandatory** — adaptive asset / dynamic colors, never hardcoded light RGB.
- Distinctive design identity, not default-SwiftUI: a warm branded palette, one reserved accent color for reward/celebration moments, and one delightful signature animation (the "Game Night Glow" / confetti / slot-machine reveal is the reference). See `design.md`.
- UX never dead-ends: always produce a result; add a rating prompt after a success moment and a share card for virality.
- Data-light by default (on-device, no accounts/trackers) — reflected in privacy copy.
- A distinctive app icon (not generic) — generate candidates and let Junior pick.
- DEBUG demo-seed + launch-arg hooks (`-seedDemo -skipNotifPrompt -showPaywall -screenshot…`) for clean `simctl` screenshots. **Never automate UI taps.**

## Verification loop (non-negotiable)
`xcodegen generate` → `swiftlint --quiet` (0 violations) → build macOS + iOS sim → `xcodebuild test` → run + screenshot → WORKLOG entry. Never claim green without a verified `BUILD SUCCEEDED`.

## App Store Connect — automatable vs human-only
Use the shared account-level tooling at `~/Documents/07-Projects/asc-tools/` (Python, ASC API key, JWT ES256) — never duplicate it per-app. Use `fastlane produce` (with a cached `spaceauth` session at `~/.fastlane/spaceship/`) for the few things the API can't do.

**Do yourself via API:** register bundle ID + capabilities (iCloud/Push/IAP); push metadata EN+PT-BR (a multiplatform app has **separate iOS and macOS `appStoreVersions`** — populate both); upload screenshots (`APP_IPHONE_67` for 6.9", `APP_IPAD_PRO_129` for 13"; every locale needs its own set); age rating; review-contact (reuse from a shipped app); content-rights; category; copyright; IAP create + localization + price + review screenshot + all-territory availability + subscription-group localization (all four needed to reach `READY_TO_SUBMIT`); attach build; submit via the `reviewSubmissions` API.

**Human-only UI gates (surface precisely, don't fight):** app-record creation (or `fastlane produce`); subscription base pricing + intro/free-trial offers (the price-point relationship is rejected by the API — confirmed); the App Privacy "Data Not Collected" questionnaire; age-assurance edge fields.

**Diagnostics:** ASC submission errors hide specifics in `meta.associatedErrors` — always read that.

## Signing
- **Default to a CI release pipeline.** Junior runs beta macOS, so local Xcode often can't submit (the App Store rejects beta-Xcode builds; GM Xcode won't run on the beta OS). Use GitHub Actions: `xcodebuild archive` + `-allowProvisioningUpdates` + ASC API-key auth, `exportArchive … destination: upload`. One-command releases (`gh workflow run`). Version bumps = edit `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION`, push, trigger CI.
- **Local-archive fallback gotcha:** a *local* `xcodebuild archive` with an API key + `-allowProvisioningUpdates` fails ("bearer token"). If you must archive locally, use Xcode's logged-in account session (no `-authenticationKey*` args) — that auto-creates the iCloud container + App Store profile. Use the API key only for the `altool` upload.

## Naming & brand
- Before proposing a name, verify it's clean on every axis: App Store availability (authoritatively, by attempting to set it via API; also iTunes Search API for collisions), `.com`/`.app` domain (RDAP), trademark (USPTO/CIPO). Prefer coined/ownable names — dictionary names are saturated. Don't impulse-buy domains; prefer Cloudflare Registrar (at-cost).
- On any rename, align every surface: ASC name + subtitle, on-device `CFBundleDisplayName`, usage strings, doc URLs/content, the privacy email. Keep internal identifiers stable (bundle ID, repo/Xcode project name) — they're locked to the ASC record and invisible to users.
