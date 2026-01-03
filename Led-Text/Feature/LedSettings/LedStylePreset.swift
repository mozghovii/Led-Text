import UIKit

struct LedStylePreset: Equatable {
    let id: String
    let name: String
    let backgroundColor: UIColor
    let textColor: UIColor
    let glowIntensity: CGFloat
    let fontName: String
    let fontSize: CGFloat
    let letterSpacing: CGFloat
    let dotMatrixEnabled: Bool

    static let all: [LedStylePreset] = [
        LedStylePreset(
            id: "classic-red",
            name: "Classic",
            backgroundColor: .black,
            textColor: .systemRed,
            glowIntensity: 0.7,
            fontName: "Menlo-Bold",
            fontSize: 32,
            letterSpacing: 1,
            dotMatrixEnabled: true
        ),
        LedStylePreset(
            id: "amber",
            name: "Amber",
            backgroundColor: UIColor(red: 0.08, green: 0.05, blue: 0.0, alpha: 1),
            textColor: UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 1),
            glowIntensity: 0.6,
            fontName: "Menlo-Bold",
            fontSize: 30,
            letterSpacing: 1,
            dotMatrixEnabled: true
        ),
        LedStylePreset(
            id: "ice",
            name: "Ice",
            backgroundColor: UIColor(red: 0.05, green: 0.07, blue: 0.1, alpha: 1),
            textColor: UIColor(red: 0.6, green: 0.9, blue: 1, alpha: 1),
            glowIntensity: 0.8,
            fontName: "Menlo-Bold",
            fontSize: 32,
            letterSpacing: 0.8,
            dotMatrixEnabled: true
        ),
        LedStylePreset(
            id: "neon",
            name: "Neon",
            backgroundColor: .black,
            textColor: UIColor(red: 0.4, green: 1.0, blue: 0.7, alpha: 1),
            glowIntensity: 0.9,
            fontName: "AvenirNext-Bold",
            fontSize: 34,
            letterSpacing: 0.5,
            dotMatrixEnabled: false
        ),
        LedStylePreset(
            id: "matrix",
            name: "Matrix",
            backgroundColor: .black,
            textColor: UIColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1),
            glowIntensity: 0.5,
            fontName: "Menlo-Bold",
            fontSize: 30,
            letterSpacing: 1.2,
            dotMatrixEnabled: true
        )
    ]

    static func preset(for id: String) -> LedStylePreset {
        all.first { $0.id == id } ?? all[0]
    }
}
