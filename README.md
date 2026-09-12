
# ScreenTester iOS

由 **mohudesu** 维护的 iPhone 屏幕测试工具，使用 Swift/UIKit，面向 iPhone 17，支持 iOS 17.0 及以上。

提供黑边检测、像素分区、圆角校准、纯色、灰阶、白平衡、彩条、触控网格和多指触控测试。

<img src="ScreenTester/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="144" alt="ScreenTester 动漫头像图标">

**v0.3.1：全新动漫头像图标，以及新拟态 / Liquid Glass 双风格界面。**

新增 Liquid Glass 风格，可在「首页右上角设置 → 界面风格」切换新拟态 / Liquid Glass。选择立即应用并保存在本机，检测参数保持不变。支持浅色/深色、大字、减少动态效果及减少透明度；首次启动沿用新拟态。

[使用与交付说明](LOCAL-交付说明.md) · [交互预览](Preview/index.html) · [构建记录](CLOUD-BUILD.json) · [图标生成说明](Design/ICON-PROMPT.md)

Windows 可直接用浏览器打开 `Preview/index.html` 比较界面；网页预览不是 iOS 运行结果。原生玻璃材质需 Xcode 26 / iOS 26，较旧系统使用磨砂兼容效果。在 Mac 工程目录运行 `bash test-ui.command` 验证界面，运行 `bash build-ipa.command` 生成未签名 IPA。

**[下载 v0.3.1 未签名 IPA](https://github.com/mohudesu/ScreenTester-iOS/releases/download/v0.3.1/ScreenTester-iPhone17-unsigned.ipa)** · [Release 与校验文件](https://github.com/mohudesu/ScreenTester-iOS/releases/tag/v0.3.1)

已通过 Xcode ARM64 设备编译、iPhone 17 模拟器三项界面测试和 IPA 完整性校验。软件包需要自行签名后安装；实机验证尚未进行。具体版本、构建提交和校验值见 `CLOUD-BUILD.json`。


当前版本新增：设置 → 深色模式 → 跟随系统 / 浅色 / 深色；选择跨重启保存。黑边页面和首页入口显示当前设备型号，标题与说明分行排列。未知机型显示硬件标识，详见 DEVICE-MODELS.md。
