import UIKit

enum AppColorScheme: String, CaseIterable {
    case system, light, dark
    var title: String {
        switch self { case .system: return "跟随系统"; case .light: return "浅色"; case .dark: return "深色" }
    }
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self { case .system: return .unspecified; case .light: return .light; case .dark: return .dark }
    }
    static func apply(_ option: AppColorScheme) {
        Preferences.shared.colorScheme = option
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            for window in scene.windows { window.overrideUserInterfaceStyle = option.userInterfaceStyle }
        }
    }
}

enum InterfaceStyle: String, CaseIterable {
    case neumorphic
    case liquidGlass

    var title: String { self == .neumorphic ? "新拟态" : "Liquid Glass" }
    var detail: String { self == .neumorphic ? "柔和浮雕" : "清透流光" }
    var symbolName: String { self == .neumorphic ? "square.stack.3d.up" : "drop" }
}

enum AppTheme {
    static var style: InterfaceStyle { Preferences.shared.interfaceStyle }
    static func background(for style: InterfaceStyle) -> UIColor {
        UIColor { traits in
            if style == .liquidGlass {
                return traits.userInterfaceStyle == .dark
                    ? UIColor(red: 0.04, green: 0.10, blue: 0.15, alpha: 1)
                    : UIColor(red: 0.90, green: 0.95, blue: 0.97, alpha: 1)
            }
            return traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.14, blue: 0.19, alpha: 1)
                : UIColor(red: 0.91, green: 0.93, blue: 0.96, alpha: 1)
        }
    }
    static var background: UIColor { background(for: style) }
    static var ink: UIColor { style == .liquidGlass ? .label : UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.93, alpha: 1) : UIColor(red: 0.16, green: 0.21, blue: 0.29, alpha: 1) } }
    static var secondary: UIColor { UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.76, alpha: 1) : UIColor(red: 0.32, green: 0.39, blue: 0.46, alpha: 1) } }
    static var accent: UIColor {
        if style == .liquidGlass {
            return UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.45, green: 0.86, blue: 0.97, alpha: 1) : UIColor(red: 0.02, green: 0.37, blue: 0.52, alpha: 1) }
        }
        return UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.48, green: 0.76, blue: 1, alpha: 1) : UIColor(red: 0.19, green: 0.40, blue: 0.74, alpha: 1) }
    }
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
        stack.axis = .vertical
        stack.spacing = spacing
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
}

// Decorative color stays behind the navigation pages, never behind test patterns.
final class InterfaceBackdrop: UIView {
    var style: InterfaceStyle = .neumorphic { didSet { setNeedsLayout() } }
    private let wash = CAGradientLayer()
    private let blue = CAGradientLayer()
    private let mint = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        clipsToBounds = true
        for gradient in [wash, blue, mint] { layer.addSublayer(gradient) }
        for gradient in [blue, mint] {
            gradient.type = .radial
            gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 1)
        }
        registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(refreshColors))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @objc private func refreshColors() { setNeedsLayout() }
    override func layoutSubviews() {
        super.layoutSubviews()
        let dark = traitCollection.userInterfaceStyle == .dark
        let visible = style == .liquidGlass && !UIAccessibility.isReduceTransparencyEnabled
        backgroundColor = AppTheme.background(for: style)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for gradient in [wash, blue, mint] { gradient.isHidden = !visible }
        wash.frame = bounds
        wash.colors = dark
            ? [UIColor(red: 0.04, green: 0.10, blue: 0.15, alpha: 1).cgColor, UIColor(red: 0.09, green: 0.16, blue: 0.23, alpha: 1).cgColor]
            : [UIColor(red: 0.92, green: 0.97, blue: 0.99, alpha: 1).cgColor, UIColor(red: 0.82, green: 0.91, blue: 0.95, alpha: 1).cgColor]
        blue.colors = [UIColor(red: 0.30, green: 0.63, blue: 0.98, alpha: dark ? 0.30 : 0.36).cgColor, UIColor.clear.cgColor]
        mint.colors = [UIColor(red: 0.37, green: 0.88, blue: 0.77, alpha: dark ? 0.20 : 0.33).cgColor, UIColor.clear.cgColor]
        blue.frame = CGRect(x: bounds.width * 0.05, y: -bounds.height * 0.17, width: bounds.width * 1.5, height: bounds.width * 1.7)
        mint.frame = CGRect(x: -bounds.width * 0.7, y: bounds.height * 0.35, width: bounds.width * 1.8, height: bounds.width * 1.8)
        CATransaction.commit()
    }
}

final class ThemedSurface: UIControl {
    let contentView = UIView()
    private let material = UIVisualEffectView(effect: nil)
    private let lightShadow = CALayer()
    private let darkShadow = CALayer()
    private let face = CALayer()
    private let outline = CAShapeLayer()
    private let surfaceStyle: InterfaceStyle
    private let prominent: Bool
    var cornerRadius: CGFloat = 25 { didSet { setNeedsLayout() } }

    init(style: InterfaceStyle = AppTheme.style, prominent: Bool = false) {
        surfaceStyle = style
        self.prominent = prominent
        super.init(frame: .zero)
        isAccessibilityElement = false
        for layer in [lightShadow, darkShadow, face] { self.layer.addSublayer(layer) }
        AppTheme.pin(material, to: self)
        material.isUserInteractionEnabled = false
        // Direct host constraints let the card grow with its text and Dynamic Type.
        AppTheme.pin(contentView, to: self)
        outline.fillColor = UIColor.clear.cgColor
        layer.addSublayer(outline)
        configureMaterial()
        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self], action: #selector(refreshColors))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private func configureMaterial() {
        guard surfaceStyle == .liquidGlass, !UIAccessibility.isReduceTransparencyEnabled else { return }
        // Reserve the native refractive material for the primary actions.
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), prominent {
            material.effect = UIGlassEffect(style: .regular)
            return
        }
        #endif
        material.effect = UIBlurEffect(style: .systemThinMaterial)
    }
    @objc private func refreshColors() { setNeedsLayout() }
    override func layoutSubviews() {
        super.layoutSubviews()
        let dark = traitCollection.userInterfaceStyle == .dark
        let soft = surfaceStyle == .neumorphic
        let opaque = UIAccessibility.isReduceTransparencyEnabled
        let fill = AppTheme.background(for: surfaceStyle).resolvedColor(with: traitCollection).cgColor
        let radius = min(cornerRadius, min(bounds.width, bounds.height) / 2)
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for layer in [lightShadow, darkShadow, face] {
            layer.frame = bounds
            layer.cornerRadius = radius
            layer.cornerCurve = .continuous
            layer.backgroundColor = soft || opaque ? fill : UIColor.clear.cgColor
        }
        lightShadow.isHidden = !soft
        lightShadow.shadowPath = path
        lightShadow.shadowColor = UIColor.white.cgColor
        lightShadow.shadowOffset = CGSize(width: -6, height: -6)
        lightShadow.shadowRadius = 9
        lightShadow.shadowOpacity = dark ? 0.045 : 0.85
        darkShadow.shadowPath = path
        darkShadow.shadowColor = (dark ? UIColor.black : UIColor(red: 0.40, green: 0.51, blue: 0.62, alpha: 1)).cgColor
        darkShadow.shadowOffset = CGSize(width: soft ? 6 : 0, height: soft ? 7 : 8)
        darkShadow.shadowRadius = soft ? 10 : 18
        darkShadow.shadowOpacity = soft ? (dark ? 0.55 : 0.35) : (dark ? 0.22 : 0.13)
        material.layer.cornerRadius = radius
        material.layer.cornerCurve = .continuous
        material.clipsToBounds = true
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            material.cornerConfiguration = .corners(radius: .fixed(Double(radius)))
        }
        #endif
        outline.frame = bounds
        outline.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: max(0, radius - 1)).cgPath
        outline.lineWidth = isSelected ? 2 : (UIAccessibility.isDarkerSystemColorsEnabled ? 1.5 : 0.75)
        outline.strokeColor = (isSelected ? AppTheme.accent.resolvedColor(with: traitCollection) : UIColor.white.withAlphaComponent(dark ? 0.14 : 0.70)).cgColor
        CATransaction.commit()
    }
    override var isSelected: Bool { didSet { setNeedsLayout() } }
    override var isHighlighted: Bool {
        didSet {
            guard !UIAccessibility.isReduceMotionEnabled else { transform = .identity; return }
            let scale: CGFloat = surfaceStyle == .liquidGlass ? 0.98 : 0.975
            UIView.animate(withDuration: 0.20, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0,
                           options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: scale, y: scale) : .identity
            }
        }
    }
    func makeButton(id: String, title: String, action: @escaping () -> Void) {
        accessibilityIdentifier = id
        accessibilityLabel = title
        accessibilityTraits = .button
        isAccessibilityElement = true
        // The host control owns one hit target; settings panels leave their controls interactive.
        contentView.isUserInteractionEnabled = false
        addAction(UIAction { _ in action() }, for: .touchUpInside)
    }
}

class StyledPageController: UIViewController {
    let stack = AppTheme.vertical([], spacing: 24)
    private let scroll = UIScrollView()
    private let backdrop = InterfaceBackdrop()
    private var renderedStyle: InterfaceStyle?

    override func viewDidLoad() {
        super.viewDidLoad()
        AppTheme.pin(backdrop, to: view)
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = true
        scroll.accessibilityIdentifier = "page.scroll"
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 26),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -26),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -44),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -52)
        ])
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitUserInterfaceStyle.self], action: #selector(refreshAppearance))
        for name in [UIAccessibility.reduceTransparencyStatusDidChangeNotification, UIAccessibility.darkerSystemColorsStatusDidChangeNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(refreshAppearance), name: name, object: nil)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if renderedStyle != AppTheme.style { refreshAppearance() }
    }
    deinit { NotificationCenter.default.removeObserver(self) }
    @objc func refreshAppearance() {
        guard isViewLoaded else { return }
        let offset = scroll.contentOffset
        renderedStyle = AppTheme.style
        view.backgroundColor = AppTheme.background
        view.tintColor = AppTheme.accent
        view.accessibilityIdentifier = "page.\(AppTheme.style.rawValue)"
        backdrop.style = AppTheme.style
        for item in stack.arrangedSubviews { stack.removeArrangedSubview(item); item.removeFromSuperview() }
        buildContents()
        view.layoutIfNeeded()
        let minimum = -scroll.adjustedContentInset.top
        let maximum = max(minimum, scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom)
        scroll.contentOffset = CGPoint(x: 0, y: min(maximum, max(minimum, offset.y)))
    }
    func buildContents() { }
}
