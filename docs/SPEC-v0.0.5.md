# Airy v0.0.5 — Specification

> Spec-driven iteration for menu bar layout, popup polish, and feature improvements.

## Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| Menu bar layout | Two-row VStack per metric column with vertical dividers | Matches reference screenshot; readable in light/dark menu bar |
| Speed format | `K/s` compact form (e.g. `13.8 K/s`) | Fits menu bar width without dropping precision |
| SEN warning | Orange when CPU temp > 80°C | Consistent with popup memory warning threshold |
| System tab | Remove CPU temperature row | Redundant with menu bar SEN column |
| Process refresh | 3 s interval while popup open | Keeps top-apps list current without heavy polling |
| Clean result | Alert title = bytes freed | Prominent feedback on successful clean |
| Dead code | Remove PrivacyToggleGrid, PrivacyMonitorService, PrivacyStatus | Unused since privacy tab removed |
| Localization | English UI strings | README has zh-CN; in-app i18n deferred |

## Requirements Checklist

### Menu Bar (P0)

- [x] Two-row VStack per metric column with thin dividers
- [x] Reference image layout in `MenuBarLabelView.swift`
- [x] Compact speed format (`K/s` not full `KB/s` if fits)
- [x] High temp orange warning on SEN value

### Popup UI (P0)

- [x] Tighten spacing, consistent 12px horizontal padding (`AppTheme.panelHorizontalPadding`)
- [x] FreeUp: clearer scan state, "Nothing to clean" empty state
- [x] System tab: remove redundant temperature row, graph height ~64pt
- [x] Footer: settings + Open Airy only, working NSMenu (keep v0.0.4 fix)

### Features (P1)

- [x] Auto-refresh process list every 3s while popup open
- [x] Release memory shows brief alert with result message
- [x] Clean shows bytes freed prominently (alert title)
- [x] Main window: tool cards slightly smaller, cleaner typography

### Polish (P2)

- [x] AppTheme: unified accent, warning colors (`linkBlue = accent`)
- [x] Chinese strings in UI where user-facing? Keep English for now (README has zh)
- [x] Remove dead code: PrivacyToggleGrid, PrivacyMonitorService, PrivacyStatus, UserSettings privacy toggles

### Release

- [x] Version 0.0.5 everywhere
- [x] Update SPEC checklist all checked
- [x] Build + test
- [x] Install `/Applications/Airy.app`
- [x] Commit, tag `v0.0.5`, push, GitHub release with zip
- [x] Update README version note

## Menu Bar Layout

```
┌────────┬────────┬────────┬──────────────┐
│  63%   │  71%   │  87°C  │ ↑ 13.8 K/s  │
│  CPU   │  MEM   │  SEN   │ ↓ 94.2 K/s  │
└────────┴────────┴────────┴──────────────┘
     │ vertical dividers between columns
```

## Files Changed

| File | Change |
|------|--------|
| `MenuBarLabelView.swift` | Two-row column layout |
| `ByteFormatter.swift` | `formatCompactSpeed` → `K/s` |
| `AppTheme.swift` | `panelHorizontalPadding`, unified accent |
| `FreeUpTabView.swift` | Scan progress %, tighter spacing |
| `SystemTabView.swift` | Removed temp row, 64pt graph |
| `PopupPanelView.swift` | 3s refresh, clean/release alerts |
| `FooterBar.swift`, `TabHeader.swift`, `ProcessListView.swift` | 12px padding |
| `MainDashboardView.swift` | Smaller tool cards |
| `UserSettings.swift` | Removed unused privacy settings |
| Deleted privacy modules | Dead code cleanup |

## Verification

```bash
xcodebuild -project LemonCleaner.xcodeproj -scheme Airy -configuration Release build
xcodebuild -project LemonCleaner.xcodeproj -scheme Airy -configuration Debug test
cp -R build/Build/Products/Release/Airy.app /Applications/
```
