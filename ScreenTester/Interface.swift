import UIKit

private func symbol(_ name: String, size: CGFloat = 22, color: UIColor = AppTheme.accent) -> UIImageView {
    let image = UIImageView(image: UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: size, weight: .medium)))
    image.tintColor = color
    image.contentMode = .scaleAspectFit
    image.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([image.widthAnchor.constraint(equalToConstant: size + 10), image.heightAnchor.constraint(equalToConstant: size + 10)])
    return image
}

extension TestKind {
    var symbolName: String {
        ["rectangle.dashed", "ruler", "viewfinder", "circle.lefthalf.filled", "circle.bottomhalf.filled", "sun.max", "chart.bar.xaxis", "sparkles", "square.grid.3x3", "hand.draw", "waveform.path.ecg"][rawValue]
    }
    var shortDescription: String {
        ["检查屏幕边缘", "逐像素观察遮挡", "让四个圆角贴合", "纯色检查面板", "观察明暗过渡", "检查灰色均匀度", "观察色块与色阶", "查看系统显示能力", "划过每一个格子", "查看同时触点数", "观察触摸事件频率"][rawValue]
    }
}

final class HomeController: StyledPageController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "屏幕检测"
        navigationItem.backButtonTitle = "返回"
        refreshAppearance()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    override func buildContents() {
        let eyebrow = AppTheme.label("SCREEN LAB", size: 11, weight: .bold, secondary: true)
        let heading = AppTheme.label("ScreenTester", size: 30, weight: .bold)
        heading.accessibilityIdentifier = "home.title"
        let titleStack = AppTheme.vertical([eyebrow, heading], spacing: 5)
        let settings = ThemedSurface(prominent: true)
        settings.cornerRadius = 18
        settings.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([settings.widthAnchor.constraint(equalToConstant: 52), settings.heightAnchor.constraint(equalToConstant: 52)])
        let gear = symbol("slider.horizontal.3", size: 23)
        settings.contentView.addSubview(gear)
        NSLayoutConstraint.activate([gear.centerXAnchor.constraint(equalTo: settings.centerXAnchor), gear.centerYAnchor.constraint(equalTo: settings.centerYAnchor)])
        settings.makeButton(id: "home.settings", title: "测试设置") { [weak self] in self?.navigationController?.pushViewController(SettingsController(), animated: true) }
        settings.accessibilityValue = AppTheme.style.title
        settings.accessibilityHint = "调整测试参数与界面风格"
        let header = UIStackView(arrangedSubviews: [titleStack, settings])
        header.alignment = .center; header.spacing = 12
        stack.addArrangedSubview(header)
        stack.addArrangedSubview(AppTheme.label("看清每一处细节。", size: 16, secondary: true))

        let hero = ThemedSurface(prominent: true)
        let tag = AppTheme.label("从屏幕边缘开始", size: 12, weight: .semibold, secondary: true)
        let heroTitle = AppTheme.label("黑边遮挡测试", size: 23, weight: .bold)
        let description = AppTheme.label("点亮屏幕轮廓，观察钢化膜是否遮住显示区域。", size: 14, secondary: true)
        let start = AppTheme.label("开始检测  ↗", size: 15, weight: .bold)
        start.textColor = AppTheme.accent
        let heroContent = AppTheme.vertical([symbol("iphone.gen3", size: 38), tag, heroTitle, description, start], spacing: 12)
        heroContent.alignment = .leading
        AppTheme.pin(heroContent, to: hero.contentView, inset: 24)
        hero.makeButton(id: "test.border", title: "开始黑边遮挡测试") { [weak self] in self?.open(.border) }
        stack.addArrangedSubview(hero)

        addSection("边缘与校准", kinds: [.precision, .calibration])
        addSection("色彩与显示", kinds: [.color, .gray, .whiteBalance, .bars, .hdr])
        addSection("触控与响应", kinds: [.touch, .multiTouch, .sampling])

        let help = ThemedSurface()
        let helpContent = AppTheme.vertical([
            AppTheme.label("轻点切换 · 长按退出", size: 16, weight: .semibold),
            AppTheme.label("测试时长按 2 秒返回。查看操作说明与测量限制。", size: 13, secondary: true)
        ])
        AppTheme.pin(helpContent, to: help.contentView, inset: 20)
        help.makeButton(id: "home.help", title: "操作与测量限制") { [weak self] in self?.showHelp() }
        stack.addArrangedSubview(help)
        let footer = AppTheme.label("ScreenTester iOS · mohudesu", size: 12, secondary: true)
        footer.textAlignment = .center
        stack.addArrangedSubview(footer)
    }
    private func addSection(_ title: String, kinds: [TestKind]) {
        let container = AppTheme.vertical([AppTheme.label(title, size: 17, weight: .bold)], spacing: 18)
        let count = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 1 : 2
        for offset in stride(from: 0, to: kinds.count, by: count) {
            let row = UIStackView(); row.spacing = 18; row.distribution = .fillEqually
            for kind in kinds[offset..<min(offset + count, kinds.count)] {
                let card = ThemedSurface()
                let icon = symbol(kind.symbolName)
                let title = AppTheme.label(kind.title, size: 16, weight: .semibold)
                let detail = AppTheme.label(kind.shortDescription, size: 12, secondary: true)
                let content = AppTheme.vertical([icon, title, detail], spacing: 10)
                content.alignment = .leading
                AppTheme.pin(content, to: card.contentView, inset: 18)
                card.makeButton(id: "test.\(kind)", title: kind.title) { [weak self] in self?.open(kind) }
                row.addArrangedSubview(card)
            }
            if row.arrangedSubviews.count < count { row.addArrangedSubview(UIView()) }
            container.addArrangedSubview(row)
        }
        stack.addArrangedSubview(container)
    }
    private func open(_ kind: TestKind) {
        if kind == .hdr {
            let screen = view.window?.windowScene?.screen ?? UIScreen.main
            let message = String(format: "潜在 EDR 余量：%.2f×\n当前 EDR 余量：%.2f×\n系统最大刷新率：%d Hz\n原生分辨率：%.0f × %.0f\n\n余量大于 1 表示系统报告可提供扩展亮度。当前值受亮度与设备状态影响。此页不测量 nits，也不能代替 HDR 内容播放验证。", Double(screen.potentialEDRHeadroom), Double(screen.currentEDRHeadroom), screen.maximumFramesPerSecond, Double(screen.nativeBounds.width), Double(screen.nativeBounds.height))
            let alert = UIAlertController(title: kind.title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "完成", style: .default))
            present(alert, animated: true)
        } else {
            let controller = TestController(kind: kind)
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true)
        }
    }
    private func showHelp() {
        let message = "所有测试：长按 2 秒退出。色彩类测试轻点切换，提示会自动隐藏。\n\n圆角初始值只是校准起点，请在圆角校准中调节四角。圆弧近似可能与屏幕曲线不同。灵动岛、物理圆角和系统手势区域不能消除。\n\n单像素准确性受显示缩放与系统合成影响。毫米参考值默认按 iPhone 17 的 460 ppi 计算，不是实测精度。\n\n触控网格未填满不代表断触；多指数量是本次观测值；事件频率不是硬件采样率。\n\n色彩测试可自行关闭原彩和夜览。应用离线运行，不上传触控数据。"
        let alert = UIAlertController(title: "操作与测量限制", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        present(alert, animated: true)
    }
}

final class SettingsController: StyledPageController {
    private weak var selectedStyleButton: ThemedSurface?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "测试设置"
        navigationItem.largeTitleDisplayMode = .never
        refreshAppearance()
    }
    override func buildContents() {
        configureNavigationAppearance()
        stack.addArrangedSubview(AppTheme.label("调到刚刚好。", size: 27, weight: .bold))
        stack.addArrangedSubview(AppTheme.label("参数会自动保存，下一次测试继续使用。", size: 14, secondary: true))
        addStylePicker()

        func section(_ views: [UIView]) {
            let surface = ThemedSurface()
            let content = AppTheme.vertical(views, spacing: 18)
            AppTheme.pin(content, to: surface.contentView, inset: 22)
            stack.addArrangedSubview(surface)
        }
        let widthValue = AppTheme.label("\(Int(Preferences.shared.width)) px", size: 26, weight: .semibold)
        widthValue.textColor = AppTheme.accent
        widthValue.accessibilityIdentifier = "settings.widthValue"
        let width = UISlider(); width.minimumValue = 1; width.maximumValue = 12; width.value = Float(Preferences.shared.width)
        width.accessibilityLabel = "描边宽度"; width.accessibilityIdentifier = "settings.width"
        style(width)
        width.addAction(UIAction { [weak width, weak widthValue] _ in
            guard let width else { return }
            width.value = width.value.rounded()
            Preferences.shared.width = CGFloat(width.value)
            widthValue?.text = "\(Int(width.value)) px"
        }, for: .valueChanged)
        let colors = UISegmentedControl(items: ["白", "绿", "红", "青", "黄"])
        colors.selectedSegmentIndex = Preferences.shared.colorIndex
        colors.selectedSegmentTintColor = AppTheme.accent.withAlphaComponent(0.18)
        colors.setTitleTextAttributes([.foregroundColor: AppTheme.ink], for: .normal)
        colors.accessibilityIdentifier = "settings.colors"
        colors.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        colors.addAction(UIAction { [weak colors] _ in
            if let colors { Preferences.shared.colorIndex = colors.selectedSegmentIndex }
        }, for: .valueChanged)
        section([AppTheme.label("描边与颜色", size: 17, weight: .bold), widthValue, width, colors,
                 AppTheme.label("1–12 像素。细线适合观察边缘，粗线更容易辨认。", size: 12, secondary: true)])

        let bright = UISwitch(); bright.isOn = Preferences.shared.bright; bright.onTintColor = AppTheme.accent
        bright.accessibilityLabel = "临时最高亮度"; bright.accessibilityIdentifier = "settings.brightness"
        bright.setContentHuggingPriority(.required, for: .horizontal)
        bright.addAction(UIAction { [weak bright] _ in if let bright { Preferences.shared.bright = bright.isOn } }, for: .valueChanged)
        let brightRow = UIStackView(arrangedSubviews: [AppTheme.label("临时最高亮度", size: 17, weight: .bold), bright])
        brightRow.alignment = .center; brightRow.spacing = 16
        section([brightRow, AppTheme.label("进入测试时提高亮度，退出测试或进入后台后恢复。", size: 13, secondary: true)])

        let ppiValue = AppTheme.label("\(Int(Preferences.shared.ppi)) ppi", size: 26, weight: .semibold)
        ppiValue.textColor = AppTheme.accent
        ppiValue.accessibilityIdentifier = "settings.ppiValue"
        let ppi = UISlider(); ppi.minimumValue = 200; ppi.maximumValue = 650; ppi.value = Float(Preferences.shared.ppi)
        ppi.accessibilityLabel = "像素密度"; ppi.accessibilityIdentifier = "settings.ppi"
        style(ppi)
        ppi.addAction(UIAction { [weak ppi, weak ppiValue] _ in
            guard let ppi else { return }
            ppi.value = ppi.value.rounded()
            Preferences.shared.ppi = CGFloat(ppi.value)
            ppiValue?.text = "\(Int(ppi.value)) ppi"
        }, for: .valueChanged)
        section([AppTheme.label("像素密度", size: 17, weight: .bold), ppiValue, ppi,
                 AppTheme.label("iPhone 17 默认 460 ppi。仅用于毫米换算，不代表测量精度。", size: 13, secondary: true)])
        section([AppTheme.label("圆角校准", size: 17, weight: .bold), AppTheme.label("返回首页打开「圆角校准」，实时调整四个角。所有设置仅保存在本机。", size: 13, secondary: true)])
    }
    private func configureNavigationAppearance() {
        if AppTheme.style == .liquidGlass {
            // Let the system navigation bar supply its native material.
            navigationItem.standardAppearance = nil
            navigationItem.scrollEdgeAppearance = nil
            navigationItem.compactAppearance = nil
        } else {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = AppTheme.background
            appearance.shadowColor = .clear
            appearance.titleTextAttributes = [.foregroundColor: AppTheme.ink]
            navigationItem.standardAppearance = appearance
            navigationItem.scrollEdgeAppearance = appearance
            navigationItem.compactAppearance = appearance
        }
        navigationController?.navigationBar.tintColor = AppTheme.accent
    }
    private func addStylePicker() {
        let title = AppTheme.label("界面风格", size: 17, weight: .bold)
        let current = AppTheme.label("当前：\(AppTheme.style.title)", size: 12, secondary: true)
        current.accessibilityIdentifier = "settings.styleValue"
        let choices = UIStackView()
        choices.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
        choices.distribution = .fillEqually
        choices.spacing = 16
        for option in InterfaceStyle.allCases {
            let button = ThemedSurface(style: option)
            button.cornerRadius = 22
            let selected = AppTheme.style == option
            let icon = symbol(option.symbolName, size: 23)
            let check = symbol(selected ? "checkmark.circle.fill" : "circle", size: 18,
                               color: selected ? AppTheme.accent : AppTheme.secondary)
            let top = UIStackView(arrangedSubviews: [icon, UIView(), check])
            top.alignment = .center
            let content = AppTheme.vertical([top, AppTheme.label(option.title, size: 14, weight: .semibold),
                                             AppTheme.label(option.detail, size: 12, secondary: true)], spacing: 8)
            AppTheme.pin(content, to: button.contentView, inset: 16)
            button.makeButton(id: "settings.style.\(option.rawValue)", title: option.title) { [weak self] in
                guard let self, Preferences.shared.interfaceStyle != option else { return }
                Preferences.shared.interfaceStyle = option
                self.refreshAppearance()
                UISelectionFeedbackGenerator().selectionChanged()
                if UIAccessibility.isVoiceOverRunning {
                    UIAccessibility.post(notification: .layoutChanged, argument: self.selectedStyleButton)
                }
            }
            button.isSelected = selected
            if selected { button.accessibilityTraits.insert(.selected); selectedStyleButton = button }
            button.accessibilityValue = selected ? "已选中" : "未选中"
            button.accessibilityHint = "立即切换并保存界面风格"
            choices.addArrangedSubview(button)
        }
        stack.addArrangedSubview(AppTheme.vertical([title, choices, current], spacing: 14))
    }
    private func style(_ slider: UISlider) {
        slider.minimumTrackTintColor = AppTheme.accent
        slider.maximumTrackTintColor = AppTheme.secondary.withAlphaComponent(0.18)
        slider.thumbTintColor = .white
        slider.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }
}
