import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UINavigationController(rootViewController: HomeController())
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

enum TestKind: Int, CaseIterable {
    case border, precision, calibration, color, gray, whiteBalance, bars, hdr, touch, multiTouch, sampling
    var title: String {
        ["黑边遮挡测试", "像素精度测试", "圆角校准", "色彩与坏点", "灰阶过渡", "白平衡", "彩条测试", "HDR 能力信息", "触控网格", "多指触控", "触控事件频率"][rawValue]
    }
    var subtitle: String {
        ["全屏描边，观察钢化膜是否遮挡", "左右 2 / 4 / 1 / 6 / 8 像素分区", "四角独立手动调整；不是系统实测值", "红绿蓝、黑白及补色，轻点切换", "连续渐变与 16 / 32 / 256 级灰阶", "多级纯灰，观察均匀度和色偏", "100% / 75% 彩条与色阶参考图", "读取系统 EDR 能力，不测量峰值亮度", "划过网格，检查是否存在断触", "显示当前触点及本次观测最大数量", "统计单指事件时间戳，非硬件采样率"][rawValue]
    }
    var isTouch: Bool { [.touch, .multiTouch, .sampling].contains(self) }
}

final class Preferences {
    static let shared = Preferences()
    private let defaults = UserDefaults.standard
    var width: CGFloat {
        get { CGFloat(defaults.object(forKey: "width") as? Double ?? 2) }
        set { defaults.set(Double(newValue), forKey: "width") }
    }
    var radii: [CGFloat] {
        get { (defaults.array(forKey: "radii") as? [Double] ?? [180, 180, 180, 180]).map { CGFloat($0) } }
        set { defaults.set(newValue.map { Double($0) }, forKey: "radii") }
    }
    var ppi: CGFloat {
        get { CGFloat(defaults.object(forKey: "ppi") as? Double ?? 460) }
        set { defaults.set(Double(newValue), forKey: "ppi") }
    }
    var colorIndex: Int {
        get { defaults.integer(forKey: "color") }
        set { defaults.set(newValue, forKey: "color") }
    }
    var bright: Bool {
        get { defaults.bool(forKey: "bright") }
        set { defaults.set(newValue, forKey: "bright") }
    }
    var color: UIColor { [UIColor.white, .systemGreen, .red, .cyan, .yellow][max(0, min(colorIndex, 4))] }
}

final class HomeController: UITableViewController {
    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ScreenTester"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "设置", style: .plain, target: self, action: #selector(settings))
    }
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { section == 0 ? TestKind.allCases.count : 1 }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { section == 0 ? "iPhone 屏幕检测" : "使用说明" }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == 0 ? "测试全屏显示，长按 2 秒退出。请用肉眼观察屏幕，截图无法记录钢化膜遮挡或面板坏点。" : "基于 byHydrogen/ScreenTester 功能移植的非官方 iOS 版。灵动岛、屏幕物理圆角及系统手势区域不能由应用消除。"
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        if indexPath.section == 0 {
            let kind = TestKind.allCases[indexPath.row]
            cell.textLabel?.text = kind.title
            cell.detailTextLabel?.text = kind.subtitle
        } else {
            cell.textLabel?.text = "操作与测量限制"
            cell.detailTextLabel?.text = "首次使用请阅读，圆角需要手动校准"
        }
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0 else {
            let alert = UIAlertController(title: "测试说明", message: "所有测试：长按 2 秒退出。纯色、灰阶、白平衡和彩条：轻点切换。\n\n黑边检测前请先在圆角校准中调节四角。初始圆角只是起点，并非 iPhone 17 实测数据；屏幕角落曲线与圆弧可能不完全相同。\n\n像素尺寸按当前屏幕 nativeScale 换算；显示缩放或系统合成可能影响单像素准确性。毫米参考值默认按 iPhone 17 官方 460 ppi 计算，不等于测量仪器精度。\n\n触控网格只记录实际收到触点的位置，未填满不代表坏点；系统边缘手势可能截获触摸。多指数量是本次观测值。\n\n颜色测试前可自行关闭原彩和夜览以减少色温变化；应用不会修改这些系统设置。HDR 页面仅查询能力，没有 HDR 测试视频。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .default))
            present(alert, animated: true)
            return
        }
        let kind = TestKind.allCases[indexPath.row]
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
    @objc private func settings() { navigationController?.pushViewController(SettingsController(), animated: true) }
}

final class SettingsController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "测试设置"
        view.backgroundColor = .systemGroupedBackground
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48)
        ])
        func label(_ text: String) -> UILabel {
            let label = UILabel(); label.text = text; label.numberOfLines = 0
            label.font = .preferredFont(forTextStyle: .body)
            stack.addArrangedSubview(label)
            return label
        }
        let widthLabel = label("描边宽度：\(Int(Preferences.shared.width)) px")
        let width = UISlider(); width.minimumValue = 1; width.maximumValue = 12; width.value = Float(Preferences.shared.width)
        width.addAction(UIAction { [weak width, weak widthLabel] _ in
            guard let width else { return }
            Preferences.shared.width = CGFloat(width.value.rounded())
            widthLabel?.text = "描边宽度：\(Int(Preferences.shared.width)) px"
        }, for: .valueChanged)
        stack.addArrangedSubview(width)
        _ = label("描边颜色")
        let colors = UISegmentedControl(items: ["白", "绿", "红", "青", "黄"])
        colors.selectedSegmentIndex = Preferences.shared.colorIndex
        colors.addAction(UIAction { [weak colors] _ in
            if let colors { Preferences.shared.colorIndex = colors.selectedSegmentIndex }
        }, for: .valueChanged)
        stack.addArrangedSubview(colors)
        _ = label("测试时临时调到最高亮度（退出或进入后台时恢复）")
        let bright = UISwitch(); bright.isOn = Preferences.shared.bright
        bright.addAction(UIAction { [weak bright] _ in
            if let bright { Preferences.shared.bright = bright.isOn }
        }, for: .valueChanged)
        stack.addArrangedSubview(bright)
        _ = label("PPI：默认 460，适用于 iPhone 17。毫米数仅为换算参考。")
        let ppiLabel = label("当前：\(Int(Preferences.shared.ppi)) ppi")
        let ppi = UISlider(); ppi.minimumValue = 200; ppi.maximumValue = 650; ppi.value = Float(Preferences.shared.ppi)
        ppi.addAction(UIAction { [weak ppi, weak ppiLabel] _ in
            guard let ppi else { return }
            Preferences.shared.ppi = CGFloat(ppi.value.rounded())
            ppiLabel?.text = "当前：\(Int(Preferences.shared.ppi)) ppi"
        }, for: .valueChanged)
        stack.addArrangedSubview(ppi)
        _ = label("圆角半径在首页「圆角校准」内实时调整。\n应用离线运行，不上传屏幕或触控数据。")
    }
}
