# Airy

A lightweight macOS menu bar utility for system monitoring and cleanup. Built with native Swift and SwiftUI (formerly Lemon Cleaner).

**中文文档:** [README.zh-CN.md](README.zh-CN.md)

## Features

### Menu Bar

- Two-row compact metrics: CPU / MEM / SEN / network speeds with column dividers
- Click to open a minimal popup panel

### FreeUp Panel

- Recoverable disk space with **Clean** (disabled when nothing is found)
- Memory usage with **Release** (runs `purge` or memory pressure relief)
- Top 6 apps by memory usage

### System Panel

- CPU temperature, free/total disk space
- Live upload/download speeds with a mini traffic chart

### Main Window (Open Airy)

Four cleanup and analysis tools:

| Tool | Description |
|------|-------------|
| **Large File** | Find and remove files above a configurable size threshold |
| **Duplicate** | Detect duplicate files by size + SHA-256 hash |
| **Privacy Clean** | Clear browser caches (Safari, Chrome, Firefox, Edge) |
| **Disk Analyzer** | Top-level directory size breakdown |

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15 or later

## Build & Install

```bash
# Regenerate Xcode project (if sources changed)
python3 generate_xcodeproj.py

# Release build
xcodebuild -project LemonCleaner.xcodeproj -scheme Airy -configuration Release build

# Run tests
xcodebuild -project LemonCleaner.xcodeproj -scheme Airy test
```

The built app is at `build/Release/Airy.app`.

> **Note:** The Xcode *project* file is still named `LemonCleaner.xcodeproj` (historical), but the target, scheme, and product are **Airy** / `Airy.app`. Bundle ID is `com.junhey.Airy`.

To install locally:

```bash
cp -R build/Release/Airy.app /Applications/
open /Applications/Airy.app
```

## Permissions

Airy runs as a menu bar agent (`LSUIElement`) and uses sandbox-free file access for scanning. Grant permissions in **System Settings → Privacy & Security** when prompted or from Airy Settings.

| Permission | Used for | Required |
|------------|----------|----------|
| **Full Disk Access** | Scan files outside the home directory when "Scan full disk" is enabled | Optional |
| **Camera** | Display camera privacy status | Optional |
| **Microphone** | Display microphone privacy status | Optional |
| **Screen Recording** | Check screen capture permission status | Optional |
| **Automation** | Check automation permission status | Optional |

Home-directory scans (caches, logs, trash, temp) work without Full Disk Access.

## Architecture

Airy follows a layered SwiftUI architecture:

```text
App (Scenes) → Features (Views) → Core (Services / Models) → System APIs
```

| Layer | Responsibility |
|-------|----------------|
| **App** | `MenuBarExtra`, `WindowGroup`, `Settings` scene wiring |
| **Features** | Menu bar label, popup tabs, main window tools, settings UI |
| **Core** | Observable services, scan models, user preferences |
| **System APIs** | Mach (`host_statistics64`, `sysctl`), `getifaddrs`, `FileManager`, SMC/`powermetrics`, AVFoundation |

### Key Services

| Service | Role |
|---------|------|
| `SystemMonitorService` | 1 Hz polling of CPU, memory, disk, network, temperature |
| `DiskScanService` | Quick scan of caches, logs, trash, crash reports, temp |
| `ProcessMemoryService` | Top apps by RSS; memory release via `purge` |
| `CacheCleanService` | Move selected scan items to Trash |
| Scanners (`ToolServices.swift`) | `LargeFileScanner`, `DuplicateFileScanner`, `PrivacyCleanService`, `DiskAnalyzerService` |

### Scan / Clean Flow

1. **Popup (FreeUp):** `DiskScanService.scan()` enumerates known cleanup targets → user confirms → `CacheCleanService.clean()` trashes selected items → rescan.
2. **Main window tools:** `ToolScanViewModel` calls a `ScanningService` implementation → user selects items → `scanner.clean()` delegates to `CacheCleanService` → rescan.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for a detailed diagram and module map.

## Project Layout

```text
lemon-cleaner/
├── LemonCleaner/
│   ├── AiryApp.swift              # App entry & scenes
│   ├── Features/                  # MenuBar, PopupPanel, MainWindow, Settings
│   ├── Core/
│   │   ├── Services/              # Monitoring, scanning, cleaning
│   │   ├── Models/                # ScanResult, SystemMetrics, etc.
│   │   ├── Settings/              # UserSettings (UserDefaults)
│   │   └── Utilities/             # ByteFormatter
│   └── UI/Components/             # Shared SwiftUI components
├── LemonCleanerTests/
├── docs/ARCHITECTURE.md
└── generate_xcodeproj.py
```

## License

MIT
