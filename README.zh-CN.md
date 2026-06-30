# Airy

轻量级 macOS 菜单栏系统监控与清理工具，基于原生 Swift + SwiftUI 构建（原 Lemon Cleaner）。

**English:** [README.md](README.md)

## 功能

### 菜单栏

- 单行紧凑指标：`CPU  MEM  SEN  ↑↓ 网速`
- 点击弹出简约面板

### FreeUp 面板

- 可恢复空间 + **Clean**（无内容时禁用）
- 内存占用 + **Release**（调用 `purge` 或内存压力释放）
- Top 6 应用内存列表

### System 面板

- CPU 温度、磁盘剩余/总量
- 实时上传/下载速率 + 迷你流量图

### 主窗口（Open Airy）

四个清理与分析工具：

| 工具 | 说明 |
|------|------|
| **大文件查找** | 查找并删除超过阈值的大文件 |
| **重复文件** | 按文件大小 + SHA-256 哈希检测重复文件 |
| **隐私清理** | 清理浏览器缓存（Safari、Chrome、Firefox、Edge） |
| **磁盘分析器** | 顶层目录占用分析 |

## 系统要求

- macOS 13.0（Ventura）或更高版本
- Xcode 15 或更高版本

## 构建与安装

```bash
# 重新生成 Xcode 工程（源码变更后）
python3 generate_xcodeproj.py

# Release 构建
xcodebuild -project LemonCleaner.xcodeproj -scheme Airy -configuration Release build

# 运行测试
xcodebuild -project LemonCleaner.xcodeproj -scheme Airy test
```

构建产物路径：

```text
build/Release/Airy.app
```

> **说明：** Xcode *工程* 文件名仍为 `LemonCleaner.xcodeproj`（历史遗留），但 target、scheme 与产物均为 **Airy** / `Airy.app`。Bundle ID 为 `com.junhey.Airy`。

本地安装示例：

```bash
cp -R build/Release/Airy.app /Applications/
open /Applications/Airy.app
```

## 权限说明

Airy 以菜单栏代理形式运行（`LSUIElement`），扫描时直接访问文件系统。可在 **系统设置 → 隐私与安全性** 中授权，或从 Airy 设置页跳转。

| 权限 | 用途 | 是否必需 |
|------|------|----------|
| **完全磁盘访问** | 开启「全盘扫描」时访问主目录外文件 | 可选 |
| **相机** | 显示相机隐私状态 | 可选 |
| **麦克风** | 显示麦克风隐私状态 | 可选 |
| **屏幕录制** | 检测屏幕捕获权限状态 | 可选 |
| **自动化** | 检测自动化权限状态 | 可选 |

主目录内的缓存、日志、废纸篓、临时文件扫描无需完全磁盘访问。

## 架构概览

Airy 采用分层 SwiftUI 架构：

```text
App（场景） → Features（视图） → Core（服务/模型） → 系统 API
```

| 层级 | 职责 |
|------|------|
| **App** | `MenuBarExtra`、`WindowGroup`、`Settings` 场景装配 |
| **Features** | 菜单栏标签、弹出面板、主窗口工具、设置界面 |
| **Core** | 可观察服务、扫描模型、用户偏好 |
| **系统 API** | Mach（`host_statistics64`、`sysctl`）、`getifaddrs`、`FileManager`、SMC/`powermetrics`、AVFoundation |

### 核心服务

| 服务 | 作用 |
|------|------|
| `SystemMonitorService` | 每秒轮询 CPU、内存、磁盘、网络、温度 |
| `DiskScanService` | 快速扫描缓存、日志、废纸篓、崩溃报告、临时文件 |
| `ProcessMemoryService` | Top 应用内存；通过 `purge` 释放内存 |
| `CacheCleanService` | 将选中项移至废纸篓 |
| 扫描器（`ToolServices.swift`） | `LargeFileScanner`、`DuplicateFileScanner`、`PrivacyCleanService`、`DiskAnalyzerService` |

### 扫描 / 清理流程

1. **弹出面板（FreeUp）：** `DiskScanService.scan()` 枚举已知清理目标 → 用户确认 → `CacheCleanService.clean()` 移入废纸篓 → 重新扫描。
2. **主窗口工具：** `ToolScanViewModel` 调用 `ScanningService` 实现 → 用户勾选项目 → `scanner.clean()` 委托给 `CacheCleanService` → 重新扫描。

详细架构图见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

## 项目结构

```text
lemon-cleaner/
├── LemonCleaner/
│   ├── AiryApp.swift              # 应用入口与场景
│   ├── Features/                  # MenuBar、PopupPanel、MainWindow、Settings
│   ├── Core/
│   │   ├── Services/              # 监控、扫描、清理
│   │   ├── Models/                # ScanResult、SystemMetrics 等
│   │   ├── Settings/              # UserSettings（UserDefaults）
│   │   └── Utilities/             # ByteFormatter
│   └── UI/Components/             # 共享 SwiftUI 组件
├── LemonCleanerTests/
├── docs/ARCHITECTURE.md
└── generate_xcodeproj.py
```

## 许可证

MIT
