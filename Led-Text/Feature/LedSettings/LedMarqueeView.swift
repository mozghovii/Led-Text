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
            layoutImages()
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

    private let imageView1 = UIImageView()
    private let imageView2 = UIImageView()
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var blinkTimer: Timer?
    private let spacing: CGFloat = 40

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
        imageView1.alpha = 1
        imageView2.alpha = 1
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutImages()
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
        let renderedImage = renderPixelTextImage()
        imageView1.image = renderedImage
        imageView2.image = renderedImage
        layoutImages()
    }

    private func layoutImages() {
        guard let image = imageView1.image else { return }
        let y = (bounds.height - image.size.height) / 2
        let totalWidth = image.size.width + spacing

        switch direction {
        case .left:
            imageView1.frame = CGRect(x: 0, y: y, width: image.size.width, height: image.size.height)
            imageView2.frame = CGRect(x: totalWidth, y: y, width: image.size.width, height: image.size.height)
        case .right:
            imageView1.frame = CGRect(
                x: bounds.width - image.size.width,
                y: y,
                width: image.size.width,
                height: image.size.height
            )
            imageView2.frame = CGRect(
                x: imageView1.frame.minX - totalWidth,
                y: y,
                width: image.size.width,
                height: image.size.height
            )
        }
    }

    private func configureBlinkTimer() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        imageView1.alpha = 1
        imageView2.alpha = 1

        guard blinkEnabled else { return }

        blinkTimer = Timer.scheduledTimer(withTimeInterval: blinkInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            let nextAlpha: CGFloat = imageView1.alpha == 1 ? 0.2 : 1
            UIView.animate(withDuration: 0.2) {
                self.imageView1.alpha = nextAlpha
                self.imageView2.alpha = nextAlpha
            }
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
        let offset = scrollSpeed * delta * directionMultiplier

        imageView1.frame.origin.x += offset
        imageView2.frame.origin.x += offset

        if direction == .left {
            if imageView1.frame.maxX < 0 {
                imageView1.frame.origin.x = imageView2.frame.maxX + spacing
            }
            if imageView2.frame.maxX < 0 {
                imageView2.frame.origin.x = imageView1.frame.maxX + spacing
            }
        } else {
            if imageView1.frame.minX > bounds.width {
                imageView1.frame.origin.x = imageView2.frame.minX - spacing - imageView1.bounds.width
            }
            if imageView2.frame.minX > bounds.width {
                imageView2.frame.origin.x = imageView1.frame.minX - spacing - imageView2.bounds.width
            }
        }
    }

    private func renderPixelTextImage() -> UIImage {
        let pixelStep = max(dotSize + dotSpacing, 1)
        let glowAlpha = min(max(glowIntensity, 0), 1)
        let rows = max(Int(bounds.height / pixelStep), 8)
        let textBitmap = renderTextBitmap(rows: rows)
        let columns = textBitmap.width
        let canvasSize = CGSize(width: CGFloat(columns) * pixelStep, height: CGFloat(rows) * pixelStep)

        let pixelRenderer = UIGraphicsImageRenderer(size: canvasSize)
        return pixelRenderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))

            let backgroundDotColor = textColor.withAlphaComponent(0.15)
            context.cgContext.setFillColor(backgroundDotColor.cgColor)
            var backgroundRow: CGFloat = 0
            while backgroundRow < canvasSize.height {
                var backgroundCol: CGFloat = 0
                while backgroundCol < canvasSize.width {
                    let rect = CGRect(x: backgroundCol, y: backgroundRow, width: dotSize, height: dotSize)
                    context.cgContext.fillEllipse(in: rect)
                    backgroundCol += pixelStep
                }
                backgroundRow += pixelStep
            }

            guard let data = textBitmap.data else { return }
            data.withUnsafeBytes { buffer in
                let bytes = buffer.bindMemory(to: UInt8.self)
                var row = 0
                while row < rows {
                    var col = 0
                    while col < columns {
                        let index = (row * columns + col) * 4
                        if index + 3 < bytes.count {
                            let alpha = bytes[index + 3]
                            if alpha > 20 {
                                let rect = CGRect(
                                    x: CGFloat(col) * pixelStep,
                                    y: CGFloat(row) * pixelStep,
                                    width: dotSize,
                                    height: dotSize
                                )
                                if glowAlpha > 0 {
                                    let glowRect = rect.insetBy(dx: -dotSize * 0.4, dy: -dotSize * 0.4)
                                    let glowColor = textColor.withAlphaComponent(glowAlpha * 0.7)
                                    context.cgContext.setFillColor(glowColor.cgColor)
                                    context.cgContext.fillEllipse(in: glowRect)
                                }
                                context.cgContext.setFillColor(textColor.cgColor)
                                context.cgContext.fillEllipse(in: rect)
                            }
                        }
                        col += 1
                    }
                    row += 1
                }
            }
        }
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
