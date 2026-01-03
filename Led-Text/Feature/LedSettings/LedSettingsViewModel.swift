import UIKit

final class LedSettingsViewModel {
    struct Settings {
        var text: String
        var speed: CGFloat
        var direction: LedMarqueeView.Direction
        var blinkEnabled: Bool
        var blinkInterval: TimeInterval
        var textColor: UIColor
        var backgroundColor: UIColor
        var dotSize: CGFloat
        var dotSpacing: CGFloat
        var glowIntensity: CGFloat
        var presetId: String
        var fontName: String
        var fontSize: CGFloat
        var letterSpacing: CGFloat
        var dotMatrixEnabled: Bool

        static let `default` = Settings(
            text: "LED Text",
            speed: 60,
            direction: .left,
            blinkEnabled: false,
            blinkInterval: 0.6,
            textColor: .systemRed,
            backgroundColor: .black,
            dotSize: 6,
            dotSpacing: 2,
            glowIntensity: 0.7,
            presetId: LedStylePreset.all[0].id,
            fontName: "Menlo-Bold",
            fontSize: 32,
            letterSpacing: 1,
            dotMatrixEnabled: true
        )
    }

    private var observers: [UUID: (Settings) -> Void] = [:]

    private(set) var settings: Settings {
        didSet {
            observers.values.forEach { $0(settings) }
        }
    }

    init(settings: Settings = .default) {
        var appliedSettings = settings
        let presetId = UserDefaults.standard.string(forKey: Self.presetKey) ?? settings.presetId
        let preset = LedStylePreset.preset(for: presetId)
        appliedSettings = applyPresetValues(preset, to: appliedSettings)
        self.settings = appliedSettings
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

    func updateBlinkInterval(_ interval: TimeInterval) {
        settings.blinkInterval = interval
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

    func updateFontSize(_ size: CGFloat) {
        settings.fontSize = size
    }

    func updateLetterSpacing(_ spacing: CGFloat) {
        settings.letterSpacing = spacing
    }

    func applyPreset(_ preset: LedStylePreset) {
        settings = applyPresetValues(preset, to: settings)
        UserDefaults.standard.set(preset.id, forKey: Self.presetKey)
    }

    func saveCurrentMessage() {
        let message = LedSavedMessage(
            id: UUID(),
            text: settings.text,
            presetId: settings.presetId,
            speed: Double(settings.speed),
            fontSize: Double(settings.fontSize)
        )
        var messages = LedSavedMessageStore.load()
        messages.insert(message, at: 0)
        LedSavedMessageStore.save(messages)
    }

    func loadSavedMessages() -> [LedSavedMessage] {
        LedSavedMessageStore.load()
    }

    func applySavedMessage(_ message: LedSavedMessage) {
        let preset = LedStylePreset.preset(for: message.presetId)
        settings = applyPresetValues(preset, to: settings)
        settings.text = message.text
        settings.speed = CGFloat(message.speed)
        settings.fontSize = CGFloat(message.fontSize)
    }

    private func applyPresetValues(_ preset: LedStylePreset, to settings: Settings) -> Settings {
        var updated = settings
        updated.presetId = preset.id
        updated.backgroundColor = preset.backgroundColor
        updated.textColor = preset.textColor
        updated.glowIntensity = preset.glowIntensity
        updated.fontName = preset.fontName
        updated.fontSize = preset.fontSize
        updated.letterSpacing = preset.letterSpacing
        updated.dotMatrixEnabled = preset.dotMatrixEnabled
        return updated
    }

    private static let presetKey = "ledText.selectedPresetId"
}
