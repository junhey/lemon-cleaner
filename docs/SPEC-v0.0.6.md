# Airy v0.0.6 — Specification

> Footer cleanup and reliable main-window opening from menu bar popup.

## Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| Open Airy | `MainWindowPresenter` + `handlesExternalEvents` fallback | `openWindow` from MenuBarExtra `.window` is a no-op |
| Footer layout | Settings left, Open Airy right, single Spacer | Remove wasted center space |
| NSButton title | `title = ""`, `imageOnly`, hugging priority | Prevents Chinese default label "按钮" in footer |
| Footer height | 6pt vertical padding (was 8pt) | Tighter footer bar |

## Requirements Checklist

### Footer (P0)

- [x] Remove center "按钮" placeholder (NSButton default title)
- [x] Settings gear only on left (NSMenu from v0.0.4)
- [x] Single "Open Airy" button on right
- [x] No duplicate Spacers / buttons
- [x] Reduced footer padding

### Open Airy (P0)

- [x] `MainWindowPresenter.present()` replaces broken `openWindow` in popup
- [x] Register `OpenWindowAction` from `WindowGroup(id: "main")`
- [x] `airy://open-main` URL + `handlesExternalEvents` for first launch
- [x] Activate app and bring existing main window to front

### Release

- [x] Version 0.0.6 everywhere
- [x] Build + test
- [x] Install `/Applications/Airy.app`
- [x] Commit, tag `v0.0.6`, push, GitHub release with zip

## Files Changed

| File | Change |
|------|--------|
| `MainWindowPresenter.swift` | New — window open coordinator |
| `FooterBar.swift` | Simplified layout, fix NSButton title |
| `PopupPanelView.swift` | Use `MainWindowPresenter.present` |
| `AiryApp.swift` | Registrar + `handlesExternalEvents` |
| `Info.plist` | v0.0.6, `airy` URL scheme |

## Verification

```bash
xcodebuild -project LemonCleaner.xcodeproj -scheme Airy -configuration Release build
xcodebuild -project LemonCleaner.xcodeproj -scheme Airy -configuration Debug test
cp -R build-release/Build/Products/Release/Airy.app /Applications/
```
