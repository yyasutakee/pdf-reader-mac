import Foundation

struct AppearanceRepository {
    private let storageKey: String = "appearanceTheme"

    // WHY: launch restores the user's last explicit appearance choice from persistent storage.
    func loadAppearanceTheme() -> AppearanceTheme {
        guard let rawValue: String = UserDefaults.standard.string(forKey: storageKey) else { return .system }
        return AppearanceTheme(rawValue: rawValue) ?? .system
    }

    // WHY: appearance changes must survive relaunch without exposing UserDefaults to the UI.
    func persistAppearanceTheme(_ appearanceTheme: AppearanceTheme) {
        UserDefaults.standard.set(appearanceTheme.rawValue, forKey: storageKey)
    }
}
