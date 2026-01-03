import UIKit

final class LedSettingsViewModel {
    struct Settings {
        var text: String
        var speed: CGFloat
        var direction: LedMarqueeView.Direction
        var blinkEnabled: Bool
        var textColor: UIColor
        var backgroundColor: UIColor
        var dotSize: CGFloat
        var dotSpacing: CGFloat
        var glowIntensity: CGFloat

        static let `default` = Settings(
            text: "LED Text",
            speed: 60,
            direction: .left,
            blinkEnabled: false,
            textColor: .systemRed,
            backgroundColor: .black,
            dotSize: 6,
            dotSpacing: 2,
            glowIntensity: 0.7
        )
    }

    private var observers: [UUID: (Settings) -> Void] = [:]

    private(set) var settings: Settings {
        didSet {
            observers.values.forEach { $0(settings) }
        }
    }

    init(settings: Settings = .default) {
        self.settings = settings
    }

    func addObserver(_ observer: @escaping (Settings) -> Void) {
        observers[UUID()] = observer
        observer(settings)
    }

    func updateText(_ text: String) {
        settings.text = text
    }

    func updateSpeed(_ speed: CGFloat) {
        settings.speed = speed
    }

    func updateDirection(_ direction: LedMarqueeView.Direction) {
        settings.direction = direction
    }

    func updateBlinkEnabled(_ enabled: Bool) {
        settings.blinkEnabled = enabled
    }

    func updateTextColor(_ color: UIColor) {
        settings.textColor = color
    }

    func updateBackgroundColor(_ color: UIColor) {
        settings.backgroundColor = color
    }

    func updateDotSize(_ size: CGFloat) {
        settings.dotSize = size
    }

    func updateDotSpacing(_ spacing: CGFloat) {
        settings.dotSpacing = spacing
    }

    func updateGlowIntensity(_ intensity: CGFloat) {
        settings.glowIntensity = intensity
    }
}
