import Combine

@MainActor
public protocol SettingsViewModel: ObservableObject {
    var appearanceOptions: [AppearanceOption] { get }
    var selectedAppearanceIdentifier: String { get }

    // WHY: selection intent crosses the package boundary without exposing app-owned implementation details.
    func send(_ event: SettingsEvent)
}
