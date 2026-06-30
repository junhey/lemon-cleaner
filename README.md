# Lemon Cleaner

macOS 菜单栏系统清理与监控工具，原生 Swift + SwiftUI 实现。

## 功能

### 菜单栏
- 实时显示 CPU、内存、温度、网络上下行速率
- 点击弹出 360×520 简约面板

### FreeUp 面板
- 扫描可恢复空间（缓存、日志、废纸篓、临时文件）
- 一键 Clean 清理
- Top 8 应用内存占用列表
- Release 释放非活跃内存

### System 面板
- CPU 温度、风扇转速、磁盘占用
- 存储空间与网络速率
- 双向网络流量曲线图
- 隐私监控开关（相机、麦克风、屏幕、自动化）

### 主窗口（Launch Lemon）
- 大文件查找（>50MB）
- 重复文件检测（SHA256）
- 相似照片（aHash）
- 应用卸载（含关联文件）
- 浏览器隐私清理
- 启动项管理
- 磁盘分析器
- Lemon Lab 工具推荐

## 要求

- macOS 13.0+
- Xcode 15+

## 构建

```bash
# 新增 Swift 文件后需重新生成工程
python3 generate_xcodeproj.py

xcodebuild -project LemonCleaner.xcodeproj -scheme LemonCleaner -configuration Debug build

# 运行测试
xcodebuild -project LemonCleaner.xcodeproj -scheme LemonCleaner test
```

或在 Xcode 中打开 `LemonCleaner.xcodeproj` 直接运行。

## 权限说明

| 功能 | 所需权限 |
|------|----------|
| 清理用户缓存 | 无需额外权限 |
| 全盘扫描大文件/重复文件 | 完全磁盘访问权限 |
| 温度读取 | powermetrics（可选） |
| 卸载 /Applications 应用 | 管理员权限 |

在 **系统设置 → 隐私与安全性 → 完全磁盘访问权限** 中添加 Lemon Cleaner 以启用全盘扫描。

## 架构

```
LemonCleaner/
├── Core/           # 模型、服务、设置
├── Features/       # MenuBar、PopupPanel、MainWindow、Settings
└── UI/Components/  # 主题与通用组件
```

- `MenuBarExtra` + `LSUIElement` 实现无 Dock 图标的菜单栏应用
- Core 服务在后台 `Task.detached` 执行扫描，主线程更新 UI
- 零第三方依赖

## License

MIT
