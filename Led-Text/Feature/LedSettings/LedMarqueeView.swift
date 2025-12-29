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
        let font = UIFont.monospacedSystemFont(ofSize: 32, weight: .bold)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        let textSize = (text as NSString).size(withAttributes: textAttributes)
        let canvasSize = CGSize(width: ceil(textSize.width) + 4, height: ceil(textSize.height) + 4)

        let textRenderer = UIGraphicsImageRenderer(size: canvasSize)
        let textImage = textRenderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))
            (text as NSString).draw(at: CGPoint(x: 2, y: 2), withAttributes: textAttributes)
        }

        let pixelStep = dotSize + dotSpacing
        let pixelRenderer = UIGraphicsImageRenderer(size: canvasSize)
        return pixelRenderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))

            guard let cgImage = textImage.cgImage else { return }
            let width = cgImage.width
            let height = cgImage.height
            guard let data = cgImage.dataProvider?.data as Data? else { return }

            data.withUnsafeBytes { buffer in
                let bytes = buffer.bindMemory(to: UInt8.self)
                for row in stride(from: 0, to: height, by: Int(pixelStep)) {
                    for col in stride(from: 0, to: width, by: Int(pixelStep)) {
                        let index = (row * width + col) * 4
                        if index + 3 < bytes.count {
                            let alpha = bytes[index + 3]
                            if alpha > 40 {
                                let rect = CGRect(
                                    x: CGFloat(col),
                                    y: CGFloat(row),
                                    width: dotSize,
                                    height: dotSize
                                )
                                context.cgContext.setFillColor(textColor.cgColor)
                                context.cgContext.fillEllipse(in: rect)
                            }
                        }
                    }
                }
            }
        }
    }
}
