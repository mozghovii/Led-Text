import UIKit

final class LedMarqueeView: UIView {
    enum Direction {
        case left
        case right
    }

    var text: String = "LED Text" {
        didSet { updateImages() }
    }

    var textColor: UIColor = .systemRed {
        didSet { updateImages() }
    }

    var scrollSpeed: CGFloat = 60

    var direction: Direction = .left {
        didSet { updateImageFrames() }
    }

    var blinkEnabled: Bool = false {
        didSet { configureBlinkTimer() }
    }

    var blinkInterval: TimeInterval = 0.6 {
        didSet { configureBlinkTimer() }
    }

    var dotSize: CGFloat = 6 {
        didSet { updateImages() }
    }

    var dotSpacing: CGFloat = 2 {
        didSet { updateImages() }
    }

    var glowIntensity: CGFloat = 0.7 {
        didSet { updateImages() }
    }

    var font: UIFont = UIFont.monospacedSystemFont(ofSize: 32, weight: .bold) {
        didSet { updateImages() }
    }

    var letterSpacing: CGFloat = 0 {
        didSet { updateImages() }
    }

    var dotMatrixEnabled: Bool = true {
        didSet { updateImages() }
    }

    private let imageView1 = UIImageView()
    private let imageView2 = UIImageView()
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var blinkTimer: Timer?
    private let spacing: CGFloat = 40
    private var offset: CGFloat = 0
    private var isBlinkOn: Bool = true
    private var cachedBitmap: Bitmap?
    private var contentWidth: CGFloat = 0

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
        updateImageAlpha()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateImages()
    }

    private func configureView() {
        clipsToBounds = true
        imageView1.contentMode = .left
        imageView2.contentMode = .left
        addSubview(imageView1)
        addSubview(imageView2)
        updateImages()
    }

    private func updateImages() {
        cacheBitmap()
        let image = renderContentImage()
        imageView1.image = image
        imageView2.image = image
        contentWidth = image.size.width
        updateImageFrames()
        updateImageAlpha()
    }

    private func updateImageFrames() {
        guard let image = imageView1.image, contentWidth > 0 else { return }
        let y = (bounds.height - image.size.height) / 2
        let x = offset

        switch direction {
        case .left:
            imageView1.frame = CGRect(x: x, y: y, width: image.size.width, height: image.size.height)
            imageView2.frame = CGRect(x: x + contentWidth, y: y, width: image.size.width, height: image.size.height)
        case .right:
            imageView1.frame = CGRect(x: x, y: y, width: image.size.width, height: image.size.height)
            imageView2.frame = CGRect(x: x - contentWidth, y: y, width: image.size.width, height: image.size.height)
        }
    }

    private func updateImageAlpha() {
        let alpha: CGFloat = isBlinkOn ? 1 : 0.2
        imageView1.alpha = alpha
        imageView2.alpha = alpha
    }

    private func configureBlinkTimer() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        isBlinkOn = true
        updateImageAlpha()

        guard blinkEnabled else { return }

        blinkTimer = Timer.scheduledTimer(withTimeInterval: blinkInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.isBlinkOn.toggle()
            self.updateImageAlpha()
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
        let pixelStep = dotMatrixEnabled ? max(dotSize + dotSpacing, 1) : 1
        let offsetDelta = scrollSpeed * pixelStep * delta * directionMultiplier

        offset += offsetDelta
        if contentWidth > 0 {
            if direction == .left, offset <= -contentWidth {
                offset += contentWidth
            } else if direction == .right, offset >= contentWidth {
                offset -= contentWidth
            }
        }

        updateImageFrames()
    }

    private func renderContentImage() -> UIImage {
        if dotMatrixEnabled {
            return renderDotMatrixImage()
        }
        return renderPlainTextImage()
    }

    private func renderDotMatrixImage() -> UIImage {
        let pixelStep = max(dotSize + dotSpacing, 1)
        let rows = max(Int(bounds.height / pixelStep), Int(ceil(font.lineHeight)))
        let textBitmap = cachedBitmap ?? renderTextBitmap(rows: rows)
        let gapColumns = max(Int(ceil(spacing / pixelStep)), 1)
        let columns = textBitmap.width + gapColumns
        let canvasSize = CGSize(width: CGFloat(columns) * pixelStep, height: CGFloat(rows) * pixelStep)

        let offDotColor = textColor.withAlphaComponent(0.12)
        let glowAlpha = min(max(glowIntensity, 0), 1)
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))

            guard let data = textBitmap.data else { return }
            data.withUnsafeBytes { buffer in
                let bytes = buffer.bindMemory(to: UInt8.self)
                for row in 0..<rows {
                    for col in 0..<columns {
                        let index = (row * textBitmap.width + col) * 4
                        let alpha: UInt8
                        if col < textBitmap.width, index + 3 < bytes.count {
                            alpha = bytes[index + 3]
                        } else {
                            alpha = 0
                        }

                        let rect = CGRect(
                            x: CGFloat(col) * pixelStep,
                            y: CGFloat(row) * pixelStep,
                            width: dotSize,
                            height: dotSize
                        )

                        if alpha > 20 {
                            if glowAlpha > 0 {
                                let glowRect = rect.insetBy(dx: -dotSize * 0.4, dy: -dotSize * 0.4)
                                let glowColor = textColor.withAlphaComponent(glowAlpha * 0.7)
                                context.cgContext.setFillColor(glowColor.cgColor)
                                context.cgContext.fillEllipse(in: glowRect)
                            }
                            context.cgContext.setFillColor(textColor.cgColor)
                        } else {
                            context.cgContext.setFillColor(offDotColor.cgColor)
                        }
                        context.cgContext.fillEllipse(in: rect)
                    }
                }
            }
        }
    }

    private func renderPlainTextImage() -> UIImage {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .kern: letterSpacing
        ]
        let textSize = (text as NSString).size(withAttributes: attributes)
        let imageSize = CGSize(width: ceil(textSize.width) + spacing, height: ceil(textSize.height) + 4)

        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
            context.cgContext.setShadow(offset: .zero, blur: 8, color: textColor.withAlphaComponent(glowIntensity).cgColor)
            (text as NSString).draw(at: CGPoint(x: 0, y: 2), withAttributes: attributes)
        }
    }

    private func cacheBitmap() {
        guard dotMatrixEnabled else {
            cachedBitmap = nil
            return
        }
        let pixelStep = max(dotSize + dotSpacing, 1)
        let rows = max(Int(bounds.height / pixelStep), Int(ceil(font.lineHeight)))
        cachedBitmap = renderTextBitmap(rows: rows)
    }

    private func renderTextBitmap(rows: Int) -> Bitmap {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .kern: letterSpacing
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
