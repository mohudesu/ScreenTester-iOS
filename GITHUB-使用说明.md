# 在 Windows 上通过 GitHub 生成未签名 IPA

你只需要浏览器和 GitHub 账号。实际编译由 GitHub 的 macOS 机器运行，不需要本地 Mac、Xcode、Apple 账号、证书或开发者会员。生成的 IPA 由你自行签名。

**v0.2.0 新拟态版本已发布，可以直接 [下载 IPA](https://github.com/mohudesu/ScreenTester-iOS/releases/download/v0.2.0/ScreenTester-iPhone17-unsigned.ipa)，无需自己编译。** [Release 页面](https://github.com/mohudesu/ScreenTester-iOS/releases/tag/v0.2.0) 同时提供校验文件。已通过 iPhone 17 模拟器界面测试、ARM64 设备编译和 IPA 完整性校验，安装前仍需自行签名。

当前仓库已经配置好。需要重新编译时，可直接跳到第 3 步；第 1、2 步供迁移到新仓库时参考。

## 1. 创建你自己的仓库

打开 https://github.com/new ，仓库名填写 `ScreenTester-iOS`。你可以选择公开或私有；公开仓库的标准 GitHub 托管 runner 使用免费，私有仓库受账户 Actions 额度和计费设置限制。此配置支持手动触发，也会在 main 分支的代码或构建配置变更时自动编译；只改说明文件不会触发。

可以勾选 Add a README file，点击 Create repository。

## 2. 上传工程文件

将 `ScreenTester-iOS-GitHub.zip` 解压。在仓库 Code 页面选择 Add file → Upload files。

打开解压后的文件夹，**把里面的所有文件和文件夹上传到仓库根目录**，包括 `.github`。不要只上传 ZIP，也不要把整个工程再套在一层目录下。点击 Commit changes，提交到默认分支。

上传后仓库根目录应是：

```text
.github/
  workflows/
    build-ios.yml
ScreenTester/
ScreenTester.xcodeproj/
UITests/
build-ipa.command
test-ui.command
verify-on-mac.command
...
```

确认 `ScreenTester` 下的 Swift 文件、Info.plist、Assets.xcassets 都已上传；`ScreenTester.xcodeproj` 下需要有 project.pbxproj 和 xcshareddata。

如果网页上传漏掉 `.github`，在 GitHub 选择 Add file → Create new file，文件名输入 `.github/workflows/build-ios.yml`，用记事本打开本地同名文件，将全文复制到网页并 Commit changes。只有根目录下 `.github/workflows/` 中的配置会被识别。

## 3. 开始编译

点击仓库顶部 Actions → 左侧 **Build unsigned IPA** → 右侧 **Run workflow** → 再点击绿色 **Run workflow**。

如果没有显示任务或运行按钮，检查配置是否上传到了默认分支，以及仓库 Settings → Actions → General 是否允许 GitHub Actions。配置使用 GitHub 官方的 checkout、upload-artifact 两个 action。

进入运行详情，可查看 Check project and Xcode、Verify UI in iPhone simulator、Build and package unsigned IPA 的输出。

## 4. 下载 IPA

运行成功显示绿色对勾后，打开该次运行详情，在页面底部 **Artifacts** 点击 **ScreenTester-unsigned-IPA**。浏览器可能下载一个 ZIP，将它解压，里面的 `ScreenTester-unsigned-时间戳.ipa` 才是可用于自签的包；另一文件是 SHA-256。

构建产物设置为保留 7 天（这是 GitHub 下载文件的保留期限，不是签名有效期）。可在过期后重新运行构建。

Release 附件不受 Artifacts 的 7 天期限影响。界面截图在 **ScreenTester-interface-previews**。发布流程会在 main 分支构建成功后创建 v0.2.0 Release；如果版本已存在，就保留已发布文件。重新编译的结果请从对应运行的 Artifacts 下载。发布后续版本时，需要同时更新应用版本和 `.github/workflows/release-ios.yml` 中的版本标签与说明。

## 编译失败怎么办

如果出现红叉，不代表签名失败，因为此流程根本不签名。进入失败步骤查看错误；也可以下载 **ScreenTester-build-logs**，把里面的 `.log` 发回本任务，我会继续修复。

如果在实际编译前就失败，可能还没有日志文件；此时复制失败步骤的网页输出即可。GitHub 有时会要求账号验证、调整 Actions 设置或处理额度问题，按它给出的具体提示处理，不用提供 Apple 密码或证书。

此版仍需要自签后在 iPhone 17 实机确认边缘像素、圆角近似与触控行为，见 DEVICE-CHECKLIST.md。

官方参考：

- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow
- https://docs.github.com/en/actions/reference/runners/github-hosted-runners
