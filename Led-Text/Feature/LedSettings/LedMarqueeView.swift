import UIKit

final class LedMarqueeView: UIView {
    enum Direction {
        case left
        case right
    }

    var text: String = "LED Text" {
        didSet {
            updateImages()
        }
    }

    var textColor: UIColor = .systemRed {
        didSet {
            updateImages()
        }
    }

    var scrollSpeed: CGFloat = 60

    var direction: Direction = .left {
        didSet {
            setNeedsDisplay()
        }
    }

    var blinkEnabled: Bool = false {
        didSet {
            configureBlinkTimer()
        }
    }

    var blinkInterval: TimeInterval = 0.6 {
        didSet {
            configureBlinkTimer()
        }
    }

    var dotSize: CGFloat = 6 {
        didSet {
            updateImages()
        }
    }

    var dotSpacing: CGFloat = 2 {
        didSet {
            updateImages()
        }
    }

    var glowIntensity: CGFloat = 0.7 {
        didSet {
            updateImages()
        }
    }

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var blinkTimer: Timer?
    private let spacing: CGFloat = 40
    private var offset: CGFloat = 0
    private var isBlinkOn: Bool = true
    private var cachedBitmap: Bitmap?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    deinit {
        stop()
    }

    func start() {
        guard displayLink == nil else { return }
        lastTimestamp = 0
        let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
        configureBlinkTimer()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        blinkTimer?.invalidate()
        blinkTimer = nil
        isBlinkOn = true
        setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cacheBitmap()
        setNeedsDisplay()
    }

    private func configureView() {
        clipsToBounds = true
        cacheBitmap()
    }

    private func updateImages() {
        offset = 0
        cacheBitmap()
        setNeedsDisplay()
    }

    private func configureBlinkTimer() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        isBlinkOn = true

        guard blinkEnabled else { return }

        blinkTimer = Timer.scheduledTimer(withTimeInterval: blinkInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.isBlinkOn.toggle()
            self.setNeedsDisplay()
        }
    }

    @objc private func handleDisplayLink(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        let delta = CGFloat(link.timestamp - lastTimestamp)
        lastTimestamp = link.timestamp

        let directionMultiplier: CGFloat = direction == .left ? -1 : 1
        let pixelStep = max(dotSize + dotSpacing, 1)
        let offset = scrollSpeed * pixelStep * delta * directionMultiplier

        self.offset += offset
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let bitmap = cachedBitmap else { return }
        let pixelStep = max(dotSize + dotSpacing, 1)
        let rows = max(Int(bounds.height / pixelStep), 1)
        let columns = max(Int(bounds.width / pixelStep), 1)
        let gapColumns = max(Int(ceil(spacing / pixelStep)), 1)
        let textWidth = bitmap.width + gapColumns

        let directionMultiplier: CGFloat = direction == .left ? -1 : 1
        let totalShift = offset * directionMultiplier
        let shiftColumns = Int(floor(totalShift / pixelStep))

        let offDotColor = textColor.withAlphaComponent(0.12)
        let glowAlpha = min(max(glowIntensity, 0), 1)
        let activeAlphaThreshold: UInt8 = 20

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)

        for row in 0..<rows {
            for col in 0..<columns {
                let mappedCol = (col + shiftColumns).modulo(textWidth)
                let alpha: UInt8
                if mappedCol < bitmap.width {
                    let index = (row * bitmap.width + mappedCol) * 4
                    if index + 3 < (bitmap.data?.count ?? 0) {
                        alpha = bitmap.data?[index + 3] ?? 0
                    } else {
                        alpha = 0
                    }
                } else {
                    alpha = 0
                }

                let rect = CGRect(
                    x: CGFloat(col) * pixelStep,
                    y: CGFloat(row) * pixelStep,
                    width: dotSize,
                    height: dotSize
                )

                if alpha > activeAlphaThreshold, isBlinkOn {
                    if glowAlpha > 0 {
                        let glowRect = rect.insetBy(dx: -dotSize * 0.4, dy: -dotSize * 0.4)
                        let glowColor = textColor.withAlphaComponent(glowAlpha * 0.7)
                        context.setFillColor(glowColor.cgColor)
                        context.fillEllipse(in: glowRect)
                    }
                    context.setFillColor(textColor.cgColor)
                } else {
                    context.setFillColor(offDotColor.cgColor)
                }
                context.fillEllipse(in: rect)
            }
        }
    }

    private func cacheBitmap() {
        let pixelStep = max(dotSize + dotSpacing, 1)
        let rows = max(Int(bounds.height / pixelStep), 8)
        let textBitmap = renderTextBitmap(rows: rows)
        cachedBitmap = textBitmap
    }

    private func renderTextBitmap(rows: Int) -> Bitmap {
        let fontSize = CGFloat(rows)
        let font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        let textSize = (text as NSString).size(withAttributes: textAttributes)
        let columns = max(Int(ceil(textSize.width)), 1)

        let width = max(columns, 1)
        let height = max(rows, 1)
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var data = Data(count: bytesPerRow * height)

        data.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return }

            context.setFillColor(UIColor.clear.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.translateBy(x: 0, y: CGFloat(rows))
            context.scaleBy(x: 1, y: -1)
            let textRect = CGRect(x: 0, y: (CGFloat(rows) - textSize.height) / 2, width: textSize.width, height: textSize.height)
            UIGraphicsPushContext(context)
            (text as NSString).draw(in: textRect, withAttributes: textAttributes)
            UIGraphicsPopContext()
        }

        return Bitmap(width: width, height: height, data: data)
    }

}

private struct Bitmap {
    let width: Int
    let height: Int
    let data: Data?
}

private extension Int {
    func modulo(_ modulus: Int) -> Int {
        guard modulus != 0 else { return 0 }
        let result = self % modulus
        return result >= 0 ? result : result + modulus
    }
}
