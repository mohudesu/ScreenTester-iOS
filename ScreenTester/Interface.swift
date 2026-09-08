import UIKit

enum SoftTheme {
    static let background = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.14, blue: 0.19, alpha: 1) : UIColor(red: 0.91, green: 0.93, blue: 0.96, alpha: 1) }
    static let ink = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.93, alpha: 1) : UIColor(red: 0.16, green: 0.21, blue: 0.29, alpha: 1) }
    static let secondary = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.72, alpha: 1) : UIColor(red: 0.36, green: 0.41, blue: 0.49, alpha: 1) }
    static let accent = UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.48, green: 0.76, blue: 1, alpha: 1) : UIColor(red: 0.19, green: 0.40, blue: 0.74, alpha: 1) }

    static func label(_ text: String, size: CGFloat = 15, weight: UIFont.Weight = .regular, secondary: Bool = false) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textColor = secondary ? self.secondary : ink
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: size, weight: weight))
        label.adjustsFontForContentSizeCategory = true
        return label
    }
    static func vertical(_ views: [UIView], spacing: CGFloat = 10) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical; stack.spacing = spacing
        return stack
    }
    static func pin(_ child: UIView, to parent: UIView, inset: CGFloat = 0) {
        child.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(child)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: inset),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -inset),
            child.topAnchor.constraint(equalTo: parent.topAnchor, constant: inset),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -inset)
        ])
    }
    static func scrollStack(in controller: UIViewController) -> UIStackView {
        controller.view.backgroundColor = background
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(scroll)
        let stack = vertical([], spacing: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 26),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -26),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -44),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -52)
        ])
        return stack
    }
}

// Shadow layers sit behind the surface so text and native controls remain crisp.
class SoftSurface: UIControl {
    let contentView = UIView()
    private let lightShadow = CALayer()
    private let darkShadow = CALayer()
    private let face = CALayer()
    var cornerRadius: CGFloat = 25
    override init(frame: CGRect) {
        super.init(frame: frame)
        for layer in [lightShadow, darkShadow, face] { self.layer.addSublayer(layer) }
        SoftTheme.pin(contentView, to: self)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        let dark = traitCollection.userInterfaceStyle == .dark
        let fill = SoftTheme.background.resolvedColor(with: traitCollection).cgColor
        CATransaction.begin(); CATransaction.setDisableActions(true)
        for layer in [lightShadow, darkShadow, face] {
            layer.frame = bounds
            layer.cornerRadius = cornerRadius
            layer.cornerCurve = .continuous
            layer.backgroundColor = fill
        }
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        lightShadow.shadowPath = path
        lightShadow.shadowColor = UIColor.white.cgColor
        lightShadow.shadowOffset = CGSize(width: -6, height: -6)
        lightShadow.shadowRadius = 9
        lightShadow.shadowOpacity = dark ? 0.045 : 0.85
        darkShadow.shadowPath = path
        darkShadow.shadowColor = (dark ? UIColor.black : UIColor(red: 0.52, green: 0.58, blue: 0.67, alpha: 1)).cgColor
        darkShadow.shadowOffset = CGSize(width: 6, height: 7)
        darkShadow.shadowRadius = 10
        darkShadow.shadowOpacity = dark ? 0.55 : 0.35
        face.borderWidth = UIAccessibility.isDarkerSystemColorsEnabled ? 1.5 : 0.75
        face.borderColor = (dark ? UIColor.white.withAlphaComponent(0.06) : UIColor.white.withAlphaComponent(0.65)).cgColor
        CATransaction.commit()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }
    override var isHighlighted: Bool {
        didSet {
            let updates = { self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.975, y: 0.975) : .identity }
            if UIAccessibility.isReduceMotionEnabled { updates() }
            else { UIView.animate(withDuration: 0.14, animations: updates) }
        }
    }
    func makeButton(id: String, title: String, action: @escaping () -> Void) {
        accessibilityIdentifier = id
        accessibilityLabel = title
        accessibilityTraits = .button
        isAccessibilityElement = true
        contentView.isUserInteractionEnabled = false
        addAction(UIAction { _ in action() }, for: .touchUpInside)
    }
}

private func symbol(_ name: String, size: CGFloat = 22, color: UIColor = SoftTheme.accent) -> UIImageView {
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

final class HomeController: UIViewController {
    private var stack: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "屏幕检测"
        navigationItem.backButtonTitle = "返回"
        stack = SoftTheme.scrollStack(in: self)
        buildPage()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory, stack != nil { buildPage() }
    }
    private func buildPage() {
        for item in stack.arrangedSubviews { stack.removeArrangedSubview(item); item.removeFromSuperview() }
        let eyebrow = SoftTheme.label("SCREEN LAB", size: 11, weight: .bold, secondary: true)
        let heading = SoftTheme.label("ScreenTester", size: 30, weight: .bold)
        heading.accessibilityIdentifier = "home.title"
        let titleStack = SoftTheme.vertical([eyebrow, heading], spacing: 5)
        let settings = SoftSurface()
        settings.cornerRadius = 18
        settings.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([settings.widthAnchor.constraint(equalToConstant: 52), settings.heightAnchor.constraint(equalToConstant: 52)])
        let gear = symbol("slider.horizontal.3", size: 23)
        settings.contentView.addSubview(gear)
        NSLayoutConstraint.activate([gear.centerXAnchor.constraint(equalTo: settings.centerXAnchor), gear.centerYAnchor.constraint(equalTo: settings.centerYAnchor)])
        settings.makeButton(id: "home.settings", title: "测试设置") { [weak self] in self?.navigationController?.pushViewController(SettingsController(), animated: true) }
        let header = UIStackView(arrangedSubviews: [titleStack, settings])
        header.alignment = .center; header.spacing = 12
        stack.addArrangedSubview(header)
        stack.addArrangedSubview(SoftTheme.label("看清每一处细节。", size: 16, secondary: true))

        let hero = SoftSurface()
        let tag = SoftTheme.label("从屏幕边缘开始", size: 12, weight: .semibold, secondary: true)
        let heroTitle = SoftTheme.label("黑边遮挡测试", size: 23, weight: .bold)
        let description = SoftTheme.label("点亮屏幕轮廓，观察钢化膜是否遮住显示区域。", size: 14, secondary: true)
        let start = SoftTheme.label("开始检测  ↗", size: 15, weight: .bold)
        start.textColor = SoftTheme.accent
        let heroContent = SoftTheme.vertical([symbol("iphone.gen3", size: 38), tag, heroTitle, description, start], spacing: 12)
        heroContent.alignment = .leading
        SoftTheme.pin(heroContent, to: hero.contentView, inset: 24)
        hero.makeButton(id: "test.border", title: "开始黑边遮挡测试") { [weak self] in self?.open(.border) }
        stack.addArrangedSubview(hero)

        addSection("边缘与校准", kinds: [.precision, .calibration])
        addSection("色彩与显示", kinds: [.color, .gray, .whiteBalance, .bars, .hdr])
        addSection("触控与响应", kinds: [.touch, .multiTouch, .sampling])

        let help = SoftSurface()
        let helpContent = SoftTheme.vertical([
            SoftTheme.label("轻点切换 · 长按退出", size: 16, weight: .semibold),
            SoftTheme.label("测试时长按 2 秒返回。查看操作说明与测量限制。", size: 13, secondary: true)
        ])
        SoftTheme.pin(helpContent, to: help.contentView, inset: 20)
        help.makeButton(id: "home.help", title: "操作与测量限制") { [weak self] in self?.showHelp() }
        stack.addArrangedSubview(help)
        let footer = SoftTheme.label("ScreenTester iOS · mohudesu", size: 12, secondary: true)
        footer.textAlignment = .center
        stack.addArrangedSubview(footer)
    }
    private func addSection(_ title: String, kinds: [TestKind]) {
        let container = SoftTheme.vertical([SoftTheme.label(title, size: 17, weight: .bold)], spacing: 18)
        let count = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 1 : 2
        for offset in stride(from: 0, to: kinds.count, by: count) {
            let row = UIStackView(); row.spacing = 18; row.distribution = .fillEqually
            for kind in kinds[offset..<min(offset + count, kinds.count)] {
                let card = SoftSurface()
                let icon = symbol(kind.symbolName)
                let title = SoftTheme.label(kind.title, size: 16, weight: .semibold)
                let detail = SoftTheme.label(kind.shortDescription, size: 12, secondary: true)
                let content = SoftTheme.vertical([icon, title, detail], spacing: 10)
                content.alignment = .leading
                SoftTheme.pin(content, to: card.contentView, inset: 18)
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

final class SettingsController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "测试设置"
        navigationItem.largeTitleDisplayMode = .never
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = SoftTheme.background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: SoftTheme.ink]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = SoftTheme.accent
        let stack = SoftTheme.scrollStack(in: self)
        stack.addArrangedSubview(SoftTheme.label("调到刚刚好。", size: 27, weight: .bold))
        stack.addArrangedSubview(SoftTheme.label("参数会自动保存，下一次测试继续使用。", size: 14, secondary: true))

        func section(_ views: [UIView]) {
            let surface = SoftSurface()
            let content = SoftTheme.vertical(views, spacing: 18)
            SoftTheme.pin(content, to: surface.contentView, inset: 22)
            stack.addArrangedSubview(surface)
        }
        let widthValue = SoftTheme.label("\(Int(Preferences.shared.width)) px", size: 26, weight: .semibold)
        widthValue.textColor = SoftTheme.accent
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
        colors.selectedSegmentTintColor = SoftTheme.accent.withAlphaComponent(0.18)
        colors.setTitleTextAttributes([.foregroundColor: SoftTheme.ink], for: .normal)
        colors.accessibilityIdentifier = "settings.colors"
        colors.addAction(UIAction { [weak colors] _ in
            if let colors { Preferences.shared.colorIndex = colors.selectedSegmentIndex }
        }, for: .valueChanged)
        section([SoftTheme.label("描边与颜色", size: 17, weight: .bold), widthValue, width, colors,
                 SoftTheme.label("1–12 像素。细线适合观察边缘，粗线更容易辨认。", size: 12, secondary: true)])

        let bright = UISwitch(); bright.isOn = Preferences.shared.bright; bright.onTintColor = SoftTheme.accent
        bright.accessibilityLabel = "临时最高亮度"; bright.accessibilityIdentifier = "settings.brightness"
        bright.setContentHuggingPriority(.required, for: .horizontal)
        bright.addAction(UIAction { [weak bright] _ in if let bright { Preferences.shared.bright = bright.isOn } }, for: .valueChanged)
        let brightRow = UIStackView(arrangedSubviews: [SoftTheme.label("临时最高亮度", size: 17, weight: .bold), bright])
        brightRow.alignment = .center; brightRow.spacing = 16
        section([brightRow, SoftTheme.label("进入测试时提高亮度，退出测试或进入后台后恢复。", size: 13, secondary: true)])

        let ppiValue = SoftTheme.label("\(Int(Preferences.shared.ppi)) ppi", size: 26, weight: .semibold)
        ppiValue.textColor = SoftTheme.accent
        let ppi = UISlider(); ppi.minimumValue = 200; ppi.maximumValue = 650; ppi.value = Float(Preferences.shared.ppi)
        ppi.accessibilityLabel = "像素密度"; ppi.accessibilityIdentifier = "settings.ppi"
        style(ppi)
        ppi.addAction(UIAction { [weak ppi, weak ppiValue] _ in
            guard let ppi else { return }
            ppi.value = ppi.value.rounded()
            Preferences.shared.ppi = CGFloat(ppi.value)
            ppiValue?.text = "\(Int(ppi.value)) ppi"
        }, for: .valueChanged)
        section([SoftTheme.label("像素密度", size: 17, weight: .bold), ppiValue, ppi,
                 SoftTheme.label("iPhone 17 默认 460 ppi。仅用于毫米换算，不代表测量精度。", size: 13, secondary: true)])
        section([SoftTheme.label("圆角校准", size: 17, weight: .bold), SoftTheme.label("返回首页打开「圆角校准」，实时调整四个角。所有设置仅保存在本机。", size: 13, secondary: true)])
    }
    private func style(_ slider: UISlider) {
        slider.minimumTrackTintColor = SoftTheme.accent
        slider.maximumTrackTintColor = SoftTheme.secondary.withAlphaComponent(0.18)
        slider.thumbTintColor = .white
        slider.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }
}
