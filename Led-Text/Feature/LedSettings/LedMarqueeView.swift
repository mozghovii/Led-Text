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
    private var smoothedDelta: CGFloat = 0
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
        if #available(iOS 15.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        } else {
            link.preferredFramesPerSecond = 60
        }
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
        let smoothingFactor: CGFloat = 0.12
        smoothedDelta = smoothedDelta == 0 ? delta : (smoothedDelta * (1 - smoothingFactor) + delta * smoothingFactor)

        let directionMultiplier: CGFloat = direction == .left ? -1 : 1
        let pixelStep = max(dotSize + dotSpacing, 1)
        let referenceWidth = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let widthScale = max(bounds.width / referenceWidth, 0.35)
        let offset = scrollSpeed * pixelStep * widthScale * smoothedDelta * directionMultiplier

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
        let shift = totalShift / pixelStep
        let shiftBase = Int(floor(shift))
        let shiftFraction = abs(shift - CGFloat(shiftBase))

        let offDotColor = textColor.withAlphaComponent(0.12)
        let glowAlpha = min(max(glowIntensity, 0), 1)
        let activeAlphaThreshold: UInt8 = 20

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)

        for row in 0..<rows {
            for col in 0..<columns {
                let mappedCol = (col + shiftBase).modulo(textWidth)
                let mappedNextCol = (mappedCol + 1).modulo(textWidth)

                let alphaA = sampleAlpha(bitmap: bitmap, row: row, col: mappedCol)
                let alphaB = sampleAlpha(bitmap: bitmap, row: row, col: mappedNextCol)
                let blendedAlpha = (CGFloat(alphaA) * (1 - shiftFraction)) + (CGFloat(alphaB) * shiftFraction)

                let rect = CGRect(
                    x: CGFloat(col) * pixelStep,
                    y: CGFloat(row) * pixelStep,
                    width: dotSize,
                    height: dotSize
                )

                if blendedAlpha > CGFloat(activeAlphaThreshold), isBlinkOn {
                    if glowAlpha > 0 {
                        let glowRect = rect.insetBy(dx: -dotSize * 0.4, dy: -dotSize * 0.4)
                        let glowScale = min(blendedAlpha / 255, 1)
                        let glowColor = textColor.withAlphaComponent(glowAlpha * 0.7 * glowScale)
                        context.setFillColor(glowColor.cgColor)
                        context.fillEllipse(in: glowRect)
                    }
                    let fillScale = min(blendedAlpha / 255, 1)
                    context.setFillColor(textColor.withAlphaComponent(fillScale).cgColor)
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

    private func sampleAlpha(bitmap: Bitmap, row: Int, col: Int) -> UInt8 {
        guard col >= 0, row >= 0, col < bitmap.width, row < bitmap.height else { return 0 }
        guard let data = bitmap.data else { return 0 }
        let index = (row * bitmap.width + col) * 4
        guard index + 3 < data.count else { return 0 }
        return data[index + 3]
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
