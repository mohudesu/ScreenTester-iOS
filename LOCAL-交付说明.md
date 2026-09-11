# ScreenTester iOS v0.3.0 · 动漫头像与双风格版

本次更新应用的桌面图标，并将双风格界面一起发布到 GitHub。新版 IPA 已由云端 macOS/Xcode 构建，下载到工程文件夹的上一级目录：`ScreenTester-iPhone17-v0.3.0-unsigned.ipa`（1,912,690 字节）。构建状态及文件校验记录见 `CLOUD-BUILD.json`。

[GitHub v0.3.0 Release](https://github.com/mohudesu/ScreenTester-iOS/releases/tag/v0.3.0) 提供相同软件包。已通过 ARM64 设备编译、两项 iPhone 17 模拟器界面测试和下载后校验；自签与实机验证由使用者完成。

桌面图标使用银蓝发、蓝绿眼睛的动漫小人头像；资源为 1024 × 1024 不透明 RGB PNG，iOS 自动裁切圆角。图标和生成提示词保存在项目中，重新生成 Xcode 工程会保留图标。

## 使用风格切换

打开首页右上角设置，选择「界面风格」中的 **新拟态** 或 **Liquid Glass**。

- 新拟态保留柔和的凸起卡片与双向阴影。
- Liquid Glass 增加清透卡片、蓝绿渐变底色及系统玻璃材质。
- 选择后当前设置页立即更新，返回首页会使用同一风格；重启应用后仍保留选择。
- 描边、颜色、PPI、亮度选项与圆角校准独立保存，切换界面不会重置检测参数。
- 浅色/深色跟随系统；大字使用单列卡片；减少透明度时显示不透明底色；减少动态效果时取消按压缩放。

应用的默认风格仍是新拟态。网页预览首次默认显示 Liquid Glass，方便查看新增样式。

## 先在 Windows 预览

用浏览器打开 `Preview/index.html`。点击右上角设置，切换两种风格；左侧按钮可以预览深色、大字和减少透明度。预览使用独立的浏览器本地设置，不会改变手机内的数据。

这是用 HTML/CSS 展示布局与配色的交互预览，**不等于 iOS 模拟器运行结果**。网页里的黑边画面仅演示进入和退出；其余检测入口会说明需要在 iOS 运行。

## 在 Mac 构建与验证

原生工程：`ScreenTester.xcodeproj`。推荐 Xcode 26 或更新版本，iOS 26 使用 `UIGlassEffect`；iOS 17–18 使用磨砂兼容效果。编译器早于 Swift 6.2 时会排除玻璃专用 API，使用兼容实现。

在此工程目录运行：

```bash
bash test-ui.command
bash build-ipa.command
```

界面测试需要 Python 3，以及 Xcode 中已安装的 iPhone 模拟器。测试涵盖风格切换、设置跨重启保存、返回首页及全屏测试退出，截图输出到 `output/ui-screenshots/`。每次运行生成独立的结果目录，方便重复验证。

在 Mac 运行脚本时，IPA 输出到 `output/ScreenTester-unsigned-时间戳.ipa`，由你自行签名。`VALIDATION.json` 记录离线源码检查；`CLOUD-BUILD.json` 单独记录云端 Xcode 构建和原生模拟器测试结果。实机验证需要自签安装后完成。

项目中的 `.github/workflows` 已配置 v0.3.0 的编译、界面测试与 Release 发布。仅运行本地脚本不会上传。

## 实现位置

- `ScreenTester/Appearance.swift`：主题、背景、材质卡片、字体与无障碍适配。
- `ScreenTester/Interface.swift`：首页、设置页、风格选项。
- `ScreenTester/App.swift`：风格偏好的本机持久化。
- `UITests/InterfaceTests.swift`：原生界面回归测试。

API 参考：[Apple UIGlassEffect](https://developer.apple.com/documentation/uikit/uiglasseffect)、[Apple Liquid Glass 接入指南](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)。
