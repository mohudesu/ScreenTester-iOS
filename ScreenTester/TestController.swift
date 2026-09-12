import UIKit

final class TestController: UIViewController, UIGestureRecognizerDelegate {
    let kind: TestKind
    private let canvas: TestCanvas
    private var savedBrightness: CGFloat?
    private var savedIdle = false
    private var active = false
    private var hintTimer: Timer?
    private var sampleTimer: Timer?
    private let hint = UILabel()
    private var panel: UIStackView?

    init(kind: TestKind) { self.kind = kind; canvas = TestCanvas(kind: kind); super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    override func loadView() { view = canvas }
    override func viewDidLoad() {
        super.viewDidLoad()
        let exit = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        exit.minimumPressDuration = 2
        exit.allowableMovement = 12
        exit.cancelsTouchesInView = false
        exit.delegate = self
        canvas.addGestureRecognizer(exit)
        if kind == .border {
            let modelTitle = UILabel()
            modelTitle.text = DeviceModel.borderTitle
            modelTitle.accessibilityIdentifier = "test.border.deviceTitle"
            modelTitle.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
            modelTitle.adjustsFontForContentSizeCategory = true
            modelTitle.textColor = Preferences.shared.color
            modelTitle.numberOfLines = 0
            modelTitle.textAlignment = .center
            let details = UILabel()
            details.text = "描边 \(Int(Preferences.shared.width)) px\n圆角为手动校准值\n长按 2 秒退出"
            details.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15))
            details.adjustsFontForContentSizeCategory = true
            details.textColor = .white
            details.numberOfLines = 0
            details.textAlignment = .center
            let information = UIStackView(arrangedSubviews: [modelTitle, details])
            information.axis = .vertical
            information.spacing = 20
            information.isUserInteractionEnabled = false
            information.translatesAutoresizingMaskIntoConstraints = false
            canvas.addSubview(information)
            NSLayoutConstraint.activate([
                information.centerXAnchor.constraint(equalTo: canvas.centerXAnchor),
                information.centerYAnchor.constraint(equalTo: canvas.centerYAnchor),
                information.widthAnchor.constraint(equalTo: canvas.widthAnchor, constant: -64)
            ])
        }
        if !kind.isTouch {
            let tap = UITapGestureRecognizer(target: self, action: #selector(nextPattern))
            tap.delegate = self
            tap.require(toFail: exit)
            canvas.addGestureRecognizer(tap)
        }
        hint.textAlignment = .center
        hint.numberOfLines = 0
        hint.font = .systemFont(ofSize: 14, weight: .medium)
        hint.textColor = .white
        hint.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        hint.layer.cornerRadius = 12
        hint.clipsToBounds = true
        hint.translatesAutoresizingMaskIntoConstraints = false
        canvas.addSubview(hint)
        NSLayoutConstraint.activate([
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            hint.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -70),
            hint.heightAnchor.constraint(equalToConstant: 64)
        ])
        if kind == .calibration { makeCalibrationPanel() }
        NotificationCenter.default.addObserver(self, selector: #selector(suspend), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resume), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resume()
        showHint()
        if kind == .sampling {
            sampleTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in self?.canvas.setNeedsDisplay() }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        suspend()
        hintTimer?.invalidate()
        sampleTimer?.invalidate()
    }
    deinit { NotificationCenter.default.removeObserver(self) }
    @objc private func resume() {
        guard !active, view.window != nil else { return }
        active = true
        savedIdle = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true
        if Preferences.shared.bright, let screen = view.window?.windowScene?.screen {
            savedBrightness = screen.brightness
            screen.brightness = 1
        }
    }
    @objc private func suspend() {
        guard active else { return }
        if let savedBrightness { view.window?.windowScene?.screen.brightness = savedBrightness }
        savedBrightness = nil
        UIApplication.shared.isIdleTimerDisabled = savedIdle
        active = false
        canvas.clearActiveTouches()
    }
    @objc private func longPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { dismiss(animated: true) }
    }
    @objc private func nextPattern() {
        if kind == .calibration { panel?.isHidden.toggle() }
        else { canvas.step += 1; canvas.setNeedsDisplay() }
        showHint()
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var candidate = touch.view
        while let current = candidate {
            if current is UIControl { return false }
            candidate = current.superview
        }
        return true
    }
    private func showHint() {
        hintTimer?.invalidate()
        hint.isHidden = false
        hint.text = "\(canvas.patternName)\n\(kind.isTouch ? "滑动测试" : "轻点切换") · 长按 2 秒退出"
        hintTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.hint.isHidden = true }
    }
    private func makeCalibrationPanel() {
        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 8
        stack.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        stack.layer.cornerRadius = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        canvas.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -64)
        ])
        let heading = UILabel(); heading.text = "手动校准 · 轻点空白隐藏面板\n初始值未经实机校准"; heading.numberOfLines = 0; heading.textColor = .white; heading.font = .systemFont(ofSize: 14)
        stack.addArrangedSubview(heading)
        for (index, name) in ["左上", "右上", "右下", "左下"].enumerated() {
            let label = UILabel(); label.textColor = .white; label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
            label.text = "\(name)：\(Int(Preferences.shared.radii[index])) px"
            stack.addArrangedSubview(label)
            let slider = UISlider(); slider.minimumValue = 0; slider.maximumValue = 360; slider.value = Float(Preferences.shared.radii[index])
            slider.addAction(UIAction { [weak self, weak slider, weak label] _ in
                guard let slider else { return }
                var radii = Preferences.shared.radii
                radii[index] = CGFloat(slider.value.rounded())
                Preferences.shared.radii = radii
                label?.text = "\(name)：\(Int(radii[index])) px"
                self?.canvas.setNeedsDisplay()
            }, for: .valueChanged)
            stack.addArrangedSubview(slider)
        }
        let close = UIButton(type: .system)
        close.setTitle("保存并返回", for: .normal)
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        stack.addArrangedSubview(close)
        panel = stack
    }
}
