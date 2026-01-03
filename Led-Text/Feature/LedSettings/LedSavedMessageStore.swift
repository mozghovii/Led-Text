import Foundation

struct LedSavedMessage: Codable, Equatable {
    let id: UUID
    let text: String
    let presetId: String
    let speed: Double
    let fontSize: Double
}

struct LedSavedMessageStore {
    private static let key = "ledText.savedMessages"

    static func load() -> [LedSavedMessage] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([LedSavedMessage].self, from: data)) ?? []
    }

    static func save(_ messages: [LedSavedMessage]) {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
