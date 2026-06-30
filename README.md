# Airy

macOS 菜单栏系统清理与监控工具（原 Lemon Cleaner），原生 Swift + SwiftUI。

## 功能

### 菜单栏
- 单行紧凑指标：`CPU  MEM  SEN  ↑↓ 网速`
- 点击弹出简约面板

### FreeUp 面板
- 可恢复空间 + Clean（无内容时禁用）
- 内存占用 + Release
- Top 6 应用内存列表

### System 面板
- CPU 温度、磁盘剩余/总量
- 网络速率 + 迷你流量图

### 主窗口（Open Airy）
- 大文件查找
- 重复文件检测
- 隐私清理
- 磁盘分析器

## 要求

- macOS 13.0+
- Xcode 15+

## 构建

```bash
python3 generate_xcodeproj.py

xcodebuild -project LemonCleaner.xcodeproj -scheme LemonCleaner -configuration Release build

xcodebuild -project LemonCleaner.xcodeproj -scheme LemonCleaner test
```

## License

MIT
