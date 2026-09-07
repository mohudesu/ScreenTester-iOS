# ScreenTester iOS 移植工程（待 Mac 编译）

目标：iPhone 17 使用的未签名 IPA，由用户自行签名。Swift/UIKit 原生实现，最低 iOS 17.0，竖屏，无第三方依赖。

**当前 ZIP 是源代码工程，不是 IPA。尚未在 Xcode 编译或 iPhone 实机验证。** 当前工作环境只有 Windows，最后编译步骤需要 Mac + Xcode，或使用已经配置好的 GitHub Actions 云端 macOS。

## 只有 Windows：使用 GitHub 云端编译

已提供 `.github/workflows/build-ios.yml`。将本文件夹里的所有文件上传到你自己的仓库根目录，点击 Actions → Build unsigned IPA → Run workflow。成功后在 Artifacts 下载 ScreenTester-unsigned-IPA。完整步骤见 `GITHUB-使用说明.md`。不需要 Apple 账号或签名材料。

## 在 Mac 上生成未签名 IPA

1. 安装 Xcode，首次启动完成 iOS 平台组件安装。Xcode → Settings → Locations → Command Line Tools 选择当前 Xcode。
2. 解压此工程。在终端输入 `cd `（带空格），将解压后的 `ScreenTester-iOS` 文件夹拖入终端，回车。
3. 执行：

```bash
bash build-ipa.command
```

成功后自动打开 `output` 文件夹，其中 `ScreenTester-unsigned-时间戳.ipa` 就是供你自签的软件包。另有 SHA-256 和构建日志。构建失败会立即停止，不会把源码或模拟器程序伪装为 IPA。

**不需要连接 iPhone、登录 Apple 账号、准备证书或购买开发者会员即可构建这个未签名包。** 安装时由你自行完成签名。

若编译报错，将 `output/build-时间戳.log` 发回本任务继续修复。第一次 Mac 编译尚未执行，因此不能承诺此工程已经编译通过。

可用 `bash verify-on-mac.command` 检查模拟器构建；也可以直接打开 `ScreenTester.xcodeproj`。不需要安装 Python、Homebrew、CocoaPods。`generate_project.py` 仅为维护工具，工程文件已经生成；在 Xcode 修改后不要重新运行生成器覆盖修改。

请按 `DEVICE-CHECKLIST.md` 完成自签后的实机验证，尤其是像素边缘、圆角和触控统计。

## 功能与差异

| 功能 | 此版实现 |
| --- | --- |
| 黑边遮挡 | 全屏描边，可设置颜色、1–12 px 宽度 |
| 精度模式 | 左右 2/4/1/6/8 px 五个区域；按 PPI 换算毫米参考值 |
| 圆角 | 四角独立调节并保存；初始 180 px 是校准起点，不是 iPhone 17 实测值；使用圆弧近似 |
| 纯色与坏点 | 红绿蓝、黑白、青、品红、黄；轻点切换 |
| 灰阶、白平衡 | 连续渐变、16/32/256 级灰阶及八级全屏灰度 |
| 彩条 | 100%/75% RGB 彩条、六色色阶和网格；未移植原版 SMPTE/ARIB 专业复合图 |
| HDR | 系统 EDR 余量和最大刷新率信息；未实现 HDR 内容渲染及峰值亮度测量 |
| 触控 | 网格覆盖、实时多指位置、当前/本次最大触点数 |
| 触控频率 | 最近 1 秒单指 coalescedTouches 时间戳估算；不声称是硬件采样率 |
| 设置 | 保存描边、颜色、PPI、圆角；可选择测试临时最高亮度，退出/后台恢复 |

Android 自动更新、Android 系统圆角读取、Material/Monet 主题未移植。iOS 使用原生界面。当前不是与 Android 版完全等价的已验证正式版本。

长按 2 秒退出测试；色彩类轻点切换，提示 2.5 秒后隐藏。触控测试中停住长按也会退出。圆角面板中滑动四个滑块，轻点空白可隐藏或显示面板。

iPhone 17 官方像素密度为 460 ppi，1 px 换算约 0.0552 mm，这只是理论换算，不是测量精度承诺。显示缩放、系统合成、像素排列、屏幕曲线和钢化膜形态都会影响判断。应用按 nativeScale 绘制，需实机确认单像素对齐；不能用模拟器证明物理准确性。

官方规格：https://www.apple.com.cn/iphone-17/specs/

所有触控统计留在内存中，设置保存在本机；不请求网络、相机、麦克风或照片权限。

## 上游

原项目：https://github.com/byHydrogen/ScreenTester

参考提交：`eff1098dff6cb9a8af578d528a02a8caeed4c44d`。原作者：byHydrogen。参见 `UPSTREAM-NOTICE.md`。
