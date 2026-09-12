import UIKit

final class TestCanvas: UIView {
    let kind: TestKind
    var step = 0
    private var points: [ObjectIdentifier: CGPoint] = [:]
    private var filled = Set<Int>()
    private var maximumTouches = 0
    private var primary: ObjectIdentifier?
    private var timestamps: [TimeInterval] = []
    private var lastTimestamp: TimeInterval = 0
    private let columns = 12
    private let rows = 26
    private var scale: CGFloat { window?.windowScene?.screen.nativeScale ?? UIScreen.main.nativeScale }
    private let pureColors: [UIColor] = [.red, .green, .blue, .white, .black, .cyan, .magenta, .yellow]
    private let colorNames = ["红色", "绿色", "蓝色", "白色", "黑色", "青色", "品红", "黄色"]
    private let grays: [CGFloat] = [1, 0.75, 0.5, 0.25, 0.125, 0.0625, 0.02, 0]

    init(kind: TestKind) {
        self.kind = kind
        super.init(frame: .zero)
        backgroundColor = .black
        isMultipleTouchEnabled = true
        isOpaque = true
        contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func didMoveToWindow() { super.didMoveToWindow(); contentScaleFactor = scale; setNeedsDisplay() }
    var patternName: String {
        switch kind {
        case .color: return colorNames[step % pureColors.count]
        case .gray: return ["连续灰阶", "16 级灰阶", "32 级灰阶", "256 级灰阶"][step % 4]
        case .whiteBalance: return "灰度 \(Int(grays[step % grays.count] * 100))%"
        case .bars: return ["100% RGB 彩条", "75% RGB 彩条", "六色色阶", "六色网格"][step % 4]
        default: return kind.title
        }
    }
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), bounds.width > 0, bounds.height > 0 else { return }
        context.setFillColor(UIColor.black.cgColor)
        context.fill(bounds)
        switch kind {
        case .border, .calibration: drawBorder(context)
        case .precision: drawPrecision(context)
        case .color: context.setFillColor(pureColors[step % pureColors.count].cgColor); context.fill(bounds)
        case .whiteBalance: context.setFillColor(UIColor(white: grays[step % grays.count], alpha: 1).cgColor); context.fill(bounds)
        case .gray: drawGray(context)
        case .bars: drawBars(context)
        case .touch, .multiTouch, .sampling: drawTouches(context)
        case .hdr: break
        }
    }
    private func caption(_ text: String, y: CGFloat, font: CGFloat = 16, color: UIColor = .white) {
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
        (text as NSString).draw(in: CGRect(x: 28, y: y, width: bounds.width - 56, height: 130), withAttributes: [
            .font: UIFont.monospacedDigitSystemFont(ofSize: font, weight: .medium),
            .foregroundColor: color, .paragraphStyle: paragraph
        ])
    }
    private func drawBorder(_ context: CGContext) {
        let width = Preferences.shared.width / scale
        let rect = bounds.insetBy(dx: width / 2, dy: width / 2)
        let radii = Preferences.shared.radii.map { max(0, min($0 / scale - width / 2, min(rect.width, rect.height) / 2)) }
        let path = UIBezierPath()
        let left = rect.minX, right = rect.maxX, top = rect.minY, bottom = rect.maxY
        path.move(to: CGPoint(x: left + radii[0], y: top))
        path.addLine(to: CGPoint(x: right - radii[1], y: top))
        path.addArc(withCenter: CGPoint(x: right - radii[1], y: top + radii[1]), radius: radii[1], startAngle: -.pi / 2, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: right, y: bottom - radii[2]))
        path.addArc(withCenter: CGPoint(x: right - radii[2], y: bottom - radii[2]), radius: radii[2], startAngle: 0, endAngle: .pi / 2, clockwise: true)
        path.addLine(to: CGPoint(x: left + radii[3], y: bottom))
        path.addArc(withCenter: CGPoint(x: left + radii[3], y: bottom - radii[3]), radius: radii[3], startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: left, y: top + radii[0]))
        path.addArc(withCenter: CGPoint(x: left + radii[0], y: top + radii[0]), radius: radii[0], startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
        path.close()
        Preferences.shared.color.setStroke()
        path.lineWidth = width
        path.stroke()
    }
    private func drawPrecision(_ context: CGContext) {
        // Integer pixel-aligned filled rectangles avoid half-pixel stroke placement.
        context.setShouldAntialias(false)
        context.setFillColor(Preferences.shared.color.cgColor)
        let pixel = 1 / scale
        context.fill(CGRect(x: 0, y: 0, width: bounds.width, height: pixel))
        context.fill(CGRect(x: 0, y: bounds.height - pixel, width: bounds.width, height: pixel))
        let widths = [2, 4, 1, 6, 8]
        for (index, pixels) in widths.enumerated() {
            let y = (CGFloat(index) * bounds.height * scale / 5).rounded() / scale
            let end = (CGFloat(index + 1) * bounds.height * scale / 5).rounded() / scale
            let width = CGFloat(pixels) / scale
            context.fill(CGRect(x: 0, y: y, width: width, height: end - y))
            context.fill(CGRect(x: bounds.width - width, y: y, width: width, height: end - y))
            context.setShouldAntialias(true)
            let mm = Double(CGFloat(pixels) * 25.4 / Preferences.shared.ppi)
            caption(String(format: "左右各 %d px\n约 %.3f mm（换算参考）", pixels, mm), y: (y + end) / 2 - 24, font: 16)
            context.setShouldAntialias(false)
        }
        context.setShouldAntialias(true)
    }
    private func drawGray(_ context: CGContext) {
        if step % 4 == 0 {
            let space = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: space, colors: [UIColor.black.cgColor, UIColor.white.cgColor] as CFArray, locations: [0, 1]) {
                context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: bounds.midY), end: CGPoint(x: bounds.width, y: bounds.midY), options: [])
            }
        } else {
            let count = [256, 16, 32, 256][step % 4]
            for index in 0..<count {
                let x = (CGFloat(index) * bounds.width * scale / CGFloat(count)).rounded() / scale
                let end = (CGFloat(index + 1) * bounds.width * scale / CGFloat(count)).rounded() / scale
                context.setFillColor(UIColor(white: CGFloat(index) / CGFloat(count - 1), alpha: 1).cgColor)
                context.fill(CGRect(x: x, y: 0, width: end - x, height: bounds.height))
            }
        }
    }
    private func drawBars(_ context: CGContext) {
        let colors: [(CGFloat, CGFloat, CGFloat)] = [(1,1,1), (1,1,0), (0,1,1), (0,1,0), (1,0,1), (1,0,0), (0,0,1), (0,0,0)]
        let mode = step % 4
        if mode < 2 {
            for (index, rgb) in colors.enumerated() {
                let m: CGFloat = mode == 0 ? 1 : 0.75
                context.setFillColor(UIColor(red: rgb.0 * m, green: rgb.1 * m, blue: rgb.2 * m, alpha: 1).cgColor)
                let x = (CGFloat(index) * bounds.width * scale / 8).rounded() / scale
                let end = (CGFloat(index + 1) * bounds.width * scale / 8).rounded() / scale
                context.fill(CGRect(x: x, y: 0, width: end - x, height: bounds.height))
            }
        } else {
            let six = Array(colors[1...6])
            let count = mode == 2 ? 16 : 4
            for (column, rgb) in six.enumerated() {
                for row in 0..<count {
                    let m = mode == 2 ? CGFloat(row + 1) / CGFloat(count) : CGFloat(4 - row) / 4
                    context.setFillColor(UIColor(red: rgb.0 * m, green: rgb.1 * m, blue: rgb.2 * m, alpha: 1).cgColor)
                    context.fill(CGRect(x: CGFloat(column) * bounds.width / 6, y: CGFloat(row) * bounds.height / CGFloat(count), width: bounds.width / 6 + 0.5, height: bounds.height / CGFloat(count) + 0.5))
                }
            }
        }
    }
    private func drawTouches(_ context: CGContext) {
        if kind == .touch {
            for row in 0..<rows {
                for column in 0..<columns {
                    let rect = CGRect(x: CGFloat(column) * bounds.width / CGFloat(columns), y: CGFloat(row) * bounds.height / CGFloat(rows), width: bounds.width / CGFloat(columns), height: bounds.height / CGFloat(rows))
                    context.setFillColor((filled.contains(row * columns + column) ? UIColor.systemGreen : UIColor(white: 0.1, alpha: 1)).cgColor)
                    context.fill(rect.insetBy(dx: 0.5, dy: 0.5))
                }
            }
        }
        for point in points.values {
            context.setFillColor(UIColor.cyan.withAlphaComponent(0.6).cgColor)
            context.fillEllipse(in: CGRect(x: point.x - 24, y: point.y - 24, width: 48, height: 48))
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: point.x - 30, y: point.y)); context.addLine(to: CGPoint(x: point.x + 30, y: point.y))
            context.move(to: CGPoint(x: point.x, y: point.y - 30)); context.addLine(to: CGPoint(x: point.x, y: point.y + 30)); context.strokePath()
        }
        // Keep the entire grid visible. Permanent labels would hide tested cells.
        if kind == .touch { return }
        let text: String
        if kind == .multiTouch {
            text = "当前 \(points.count) 指\n本次最多观测到 \(maximumTouches) 指\n长按 2 秒退出"
        } else {
            let now = ProcessInfo.processInfo.systemUptime
            let recent = timestamps.filter { $0 >= now - 1 }
            if recent.count >= 3, let first = recent.first, let last = recent.last, last > first, now - last < 0.25 {
                let hz = Double(recent.count - 1) / (last - first)
                text = String(format: "%.0f Hz\n最近 1 秒单指事件估算\n持续滑动；不是硬件采样率", hz)
            } else { text = "请单指持续滑动\n统计系统提供的合并触摸事件\n不是硬件采样率；长按 2 秒退出" }
        }
        let box = CGRect(x: 20, y: bounds.midY - 65, width: bounds.width - 40, height: 130)
        context.setFillColor(UIColor.black.withAlphaComponent(0.85).cgColor)
        context.fill(box)
        caption(text, y: box.minY + 18, font: 18)
    }
    private func record(_ touch: UITouch, event: UIEvent?) {
        let id = ObjectIdentifier(touch)
        let samples = event?.coalescedTouches(for: touch) ?? [touch]
        for sample in samples {
            let point = sample.location(in: self)
            if kind == .touch, bounds.contains(point), bounds.width > 0, bounds.height > 0 {
                let column = min(columns - 1, Int(point.x / bounds.width * CGFloat(columns)))
                let row = min(rows - 1, Int(point.y / bounds.height * CGFloat(rows)))
                filled.insert(row * columns + column)
            }
            if kind == .sampling, primary == id, sample.timestamp > lastTimestamp {
                timestamps.append(sample.timestamp)
                lastTimestamp = sample.timestamp
            }
        }
        timestamps.removeAll { $0 < lastTimestamp - 1 }
        points[id] = touch.location(in: self)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard kind.isTouch else { return }
        if primary == nil, let first = touches.first {
            primary = ObjectIdentifier(first); timestamps.removeAll(); lastTimestamp = 0
        }
        for touch in touches { record(touch, event: event) }
        maximumTouches = max(maximumTouches, points.count)
        setNeedsDisplay()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard kind.isTouch else { return }
        for touch in touches { record(touch, event: event) }
        setNeedsDisplay()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if kind.isTouch { record(touch, event: event) }
            points.removeValue(forKey: ObjectIdentifier(touch))
            if primary == ObjectIdentifier(touch) { primary = nil; timestamps.removeAll(); lastTimestamp = 0 }
        }
        setNeedsDisplay()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            points.removeValue(forKey: ObjectIdentifier(touch))
            if primary == ObjectIdentifier(touch) { primary = nil; timestamps.removeAll(); lastTimestamp = 0 }
        }
        setNeedsDisplay()
    }
    func clearActiveTouches() { points.removeAll(); timestamps.removeAll(); primary = nil; lastTimestamp = 0; setNeedsDisplay() }
}
