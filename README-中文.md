# ScreenTester iOS

> **v0.3.0** 新增动漫人物头像图标与 Liquid Glass / 新拟态切换。详见 [交付说明](LOCAL-交付说明.md) 和 [构建记录](CLOUD-BUILD.json)。

维护者：mohudesu。

目标：iPhone 17 使用的未签名 IPA，由用户自行签名。Swift/UIKit 原生实现，最低 iOS 17.0，竖屏，无第三方依赖。

**v0.3.0 已发布：[下载 IPA](https://github.com/mohudesu/ScreenTester-iOS/releases/download/v0.3.0/ScreenTester-iPhone17-unsigned.ipa)。** 已通过 GitHub Actions 的 Xcode ARM64 设备编译、iPhone 17 模拟器两项界面测试及安装包完整性校验。[Release 页面](https://github.com/mohudesu/ScreenTester-iOS/releases/tag/v0.3.0) 提供 SHA-256 校验文件；安装前自行签名。实机验证尚未进行。

首页与设置页采用新拟态风格，支持浅色/深色主题、动态字体及按压反馈。首页按边缘与校准、色彩与显示、触控与响应分组。

v0.3.0 增加 Liquid Glass 风格，在设置的「界面风格」中立即切换并自动保存。使用 Xcode 26 和 iOS 26 时，主要入口使用系统玻璃材质；旧系统使用磨砂兼容效果。开启「减少透明度」时使用不透明卡片。全屏测试画面保持原有绘制方式。

## 只有 Windows：使用 GitHub 云端编译

当前仓库已配置 `.github/workflows/build-ios.yml`。点击 Actions → Build unsigned IPA → Run workflow，可重新运行模拟器测试并编译。成功后在 Artifacts 下载 ScreenTester-unsigned-IPA。已发布版本可直接在 Releases 下载；完整步骤见 `GITHUB-使用说明.md`。不需要 Apple 账号或签名材料。

## 在 Mac 上生成未签名 IPA

1. 安装 Xcode，首次启动完成 iOS 平台组件安装。Xcode → Settings → Locations → Command Line Tools 选择当前 Xcode。
2. 解压此工程。在终端输入 `cd `（带空格），将解压后的 `ScreenTester-iOS` 文件夹拖入终端，回车。
3. 执行：

```bash
bash build-ipa.command
```

成功后自动打开 `output` 文件夹，其中 `ScreenTester-unsigned-时间戳.ipa` 就是供你自签的软件包。另有 SHA-256 和构建日志。构建失败会立即停止，不会把源码或模拟器程序伪装为 IPA。

**不需要连接 iPhone、登录 Apple 账号、准备证书或购买开发者会员即可构建这个未签名包。** 安装时由你自行完成签名。

若编译报错，将 `output/build-时间戳.log` 发回本任务继续修复。后续重新编译以当次构建结果为准。

可用 `bash verify-on-mac.command` 检查模拟器构建；`bash test-ui.command` 会在已安装的 iPhone 模拟器上运行界面测试并保存截图，该测试脚本需要 Python 3。也可以直接打开 `ScreenTester.xcodeproj`。仅编译 IPA 不需要 Python、Homebrew、CocoaPods。`generate_project.py` 仅为维护工具，工程文件已经生成；在 Xcode 修改后不要重新运行生成器覆盖修改。

请按 `DEVICE-CHECKLIST.md` 完成自签后的实机验证，尤其是像素边缘、圆角和触控统计。

## 功能与差异

| 功能 | 此版实现 |
| --- | --- |
| 黑边遮挡 | 全屏描边，可设置颜色、1–12 px 宽度 |
| 精度模式 | 左右 2/4/1/6/8 px 五个区域；按 PPI 换算毫米参考值 |
| 圆角 | 四角独立调节并保存；初始 180 px 是校准起点，不是 iPhone 17 实测值；使用圆弧近似 |
| 纯色与坏点 | 红绿蓝、黑白、青、品红、黄；轻点切换 |
| 灰阶、白平衡 | 连续渐变、16/32/256 级灰阶及八级全屏灰度 |
| 彩条 | 100%/75% RGB 彩条、六色色阶和网格 |
| HDR | 系统 EDR 余量和最大刷新率信息；未实现 HDR 内容渲染及峰值亮度测量 |
| 触控 | 网格覆盖、实时多指位置、当前/本次最大触点数 |
| 触控频率 | 最近 1 秒单指 coalescedTouches 时间戳估算；不声称是硬件采样率 |
| 设置 | 保存描边、颜色、PPI、圆角；可选择测试临时最高亮度，退出/后台恢复 |

使用 iOS 原生界面；不提供系统物理圆角读取、SMPTE/ARIB 复合信号图或 HDR 内容渲染。

长按 2 秒退出测试；色彩类轻点切换，提示 2.5 秒后隐藏。触控测试中停住长按也会退出。圆角面板中滑动四个滑块，轻点空白可隐藏或显示面板。

iPhone 17 官方像素密度为 460 ppi，1 px 换算约 0.0552 mm，这只是理论换算，不是测量精度承诺。显示缩放、系统合成、像素排列、屏幕曲线和钢化膜形态都会影响判断。应用按 nativeScale 绘制，需实机确认单像素对齐；不能用模拟器证明物理准确性。

官方规格：https://www.apple.com.cn/iphone-17/specs/

所有触控统计留在内存中，设置保存在本机；不请求网络、相机、麦克风或照片权限。
