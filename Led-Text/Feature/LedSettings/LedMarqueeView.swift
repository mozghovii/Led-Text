import UIKit

final class LedMarqueeView: UIView {
    enum Direction {
        case left
        case right
    }

    var text: String = "LED Text" {
        didSet {
            updateLabels()
        }
    }

    var textColor: UIColor = .systemRed {
        didSet {
            updateLabelStyle()
        }
    }

    var scrollSpeed: CGFloat = 60

    var direction: Direction = .left {
        didSet {
            updateLabels()
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

    private let label1 = UILabel()
    private let label2 = UILabel()
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
        label1.alpha = 1
        label2.alpha = 1
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLabels()
    }

    private func configureView() {
        clipsToBounds = true
        label1.font = UIFont.monospacedSystemFont(ofSize: 32, weight: .bold)
        label2.font = label1.font
        addSubview(label1)
        addSubview(label2)
        updateLabels()
        updateLabelStyle()
    }

    private func updateLabelStyle() {
        [label1, label2].forEach { label in
            label.textColor = textColor
            label.layer.shadowColor = textColor.cgColor
            label.layer.shadowRadius = 8
            label.layer.shadowOpacity = 0.9
            label.layer.shadowOffset = .zero
        }
    }

    private func updateLabels() {
        label1.text = text
        label2.text = text
        label1.sizeToFit()
        label2.sizeToFit()

        let y = (bounds.height - label1.bounds.height) / 2
        let totalWidth = label1.bounds.width + spacing

        switch direction {
        case .left:
            label1.frame = CGRect(x: 0, y: y, width: label1.bounds.width, height: label1.bounds.height)
            label2.frame = CGRect(x: totalWidth, y: y, width: label2.bounds.width, height: label2.bounds.height)
        case .right:
            label1.frame = CGRect(
                x: bounds.width - label1.bounds.width,
                y: y,
                width: label1.bounds.width,
                height: label1.bounds.height
            )
            label2.frame = CGRect(
                x: label1.frame.minX - totalWidth,
                y: y,
                width: label2.bounds.width,
                height: label2.bounds.height
            )
        }
    }

    private func configureBlinkTimer() {
        blinkTimer?.invalidate()
        blinkTimer = nil
        label1.alpha = 1
        label2.alpha = 1

        guard blinkEnabled else { return }

        blinkTimer = Timer.scheduledTimer(withTimeInterval: blinkInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            let nextAlpha: CGFloat = label1.alpha == 1 ? 0.2 : 1
            UIView.animate(withDuration: 0.2) {
                self.label1.alpha = nextAlpha
                self.label2.alpha = nextAlpha
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

        label1.frame.origin.x += offset
        label2.frame.origin.x += offset

        if direction == .left {
            if label1.frame.maxX < 0 {
                label1.frame.origin.x = label2.frame.maxX + spacing
            }
            if label2.frame.maxX < 0 {
                label2.frame.origin.x = label1.frame.maxX + spacing
            }
        } else {
            if label1.frame.minX > bounds.width {
                label1.frame.origin.x = label2.frame.minX - spacing - label1.bounds.width
            }
            if label2.frame.minX > bounds.width {
                label2.frame.origin.x = label1.frame.minX - spacing - label2.bounds.width
            }
        }
    }
}
