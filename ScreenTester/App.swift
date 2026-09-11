import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = Preferences.shared.colorScheme.userInterfaceStyle
        window.rootViewController = UINavigationController(rootViewController: HomeController())
        window.makeKeyAndVisible()
        self.window = window
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
    var colorScheme: AppColorScheme {
        get { AppColorScheme(rawValue: defaults.string(forKey: "colorScheme") ?? "") ?? .system }
        set { defaults.set(newValue.rawValue, forKey: "colorScheme") }
    }
    var interfaceStyle: InterfaceStyle {
        get { InterfaceStyle(rawValue: defaults.string(forKey: "interfaceStyle") ?? "") ?? .neumorphic }
        set { defaults.set(newValue.rawValue, forKey: "interfaceStyle") }
    }
    var width: CGFloat {
        get { CGFloat((defaults.object(forKey: "width") as? Double) ?? 2) }
        set { defaults.set(Double(newValue), forKey: "width") }
    }
    var radii: [CGFloat] {
        get { (defaults.array(forKey: "radii") as? [Double] ?? [180, 180, 180, 180]).map { CGFloat($0) } }
        set { defaults.set(newValue.map { Double($0) }, forKey: "radii") }
    }
    var ppi: CGFloat {
        get { CGFloat((defaults.object(forKey: "ppi") as? Double) ?? 460) }
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

