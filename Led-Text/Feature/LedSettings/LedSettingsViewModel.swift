import UIKit

final class LedSettingsViewModel {
    struct Settings {
        var text: String
        var speed: CGFloat
        var direction: LedMarqueeView.Direction
        var blinkEnabled: Bool
        var textColor: UIColor
        var backgroundColor: UIColor

        static let `default` = Settings(
            text: "LED Text",
            speed: 60,
            direction: .left,
            blinkEnabled: false,
            textColor: .systemRed,
            backgroundColor: .black
        )
    }

    var onChange: ((Settings) -> Void)?

    private(set) var settings: Settings {
        didSet {
            onChange?(settings)
        }
    }

    init(settings: Settings = .default) {
        self.settings = settings
    }

    func updateText(_ text: String) {
        settings.text = text.isEmpty ? Settings.default.text : text
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
}
