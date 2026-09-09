# ScreenTester iOS

由 **mohudesu** 维护的 iPhone 屏幕测试工具，使用 Swift/UIKit，面向 iPhone 17，支持 iOS 17.0 及以上。

提供黑边检测、像素分区、圆角校准、纯色、灰阶、白平衡、彩条、触控网格和多指触控测试。

**v0.2.0 已发布。** 首页与设置页采用新拟态风格，包含柔和双向阴影、分组卡片、浅色/深色主题、动态字体和按压反馈。

[下载未签名 IPA](https://github.com/mohudesu/ScreenTester-iOS/releases/latest) · [云端构建](https://github.com/mohudesu/ScreenTester-iOS/actions/workflows/build-ios.yml) · [使用说明](GITHUB-使用说明.md)

已通过 iPhone 17 模拟器的首页跳转、设置保存、全屏测试退出检查，以及 ARM64 设备编译和 IPA 完整性校验，详见 [验证记录](VALIDATION.json)。IPA 需自行签名，iPhone 实机效果仍需验证；圆角及毫米读数为观察参考，触控事件频率不代表硬件采样率。
