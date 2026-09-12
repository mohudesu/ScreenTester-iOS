# 设备型号标题

黑边测试首页入口和测试中央显示「设备型号 黑边测试」。机型通过 `hw.machine` 获取；模拟器通过 `SIMULATOR_MODEL_IDENTIFIER` 获取模拟设备型号。标题常驻，边缘测试线条保持不变。

机型映射数据核对自 [DeviceKit 设备目录](https://github.com/devicekit/DeviceKit/blob/master/Source/Device.generated.swift)，核对日期为 2026-09-11。本项目仅记录设备标识与名称事实，没有引入 DeviceKit 依赖。

目前映射覆盖可运行 iOS 17 的 iPhone XS / XR 至 iPhone 17 系列、iPhone Air、iPhone 17e。未知型号显示原始硬件标识，后续可在 `ScreenTester/DeviceModel.swift` 中补充映射。不能把 `iPhone18,2` 直接当作 iPhone 18：它对应 iPhone 17 Pro Max。

# 深色模式

在「设置 → 深色模式」选择跟随系统、浅色或深色。偏好保存在本机，应用重启时在窗口显示前恢复。选项与新拟态 / Liquid Glass 风格独立，测试画面颜色不随外观切换而变化。
