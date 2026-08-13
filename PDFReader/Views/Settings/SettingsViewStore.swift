import Combine
import SettingsFeature

@MainActor
final class SettingsViewStore: SettingsViewModel {
    @Published private(set) var appearanceOptions: [AppearanceOption] = []
    @Published private(set) var selectedAppearanceIdentifier: String = AppearanceTheme.system.rawValue

    private let appStore: AppStore
    private var storeSubscriptions: Set<AnyCancellable> = []

    init(appStore: AppStore) {
        self.appStore = appStore
        observeAppStateChanges()
        recompute(from: appStore.state)
    }

    // WHY: the settings package sends a string identifier so it never imports the domain preference type.
    func send(_ event: SettingsEvent) {
        switch event {
        case .appearanceSelected(let identifier): selectAppearanceTheme(identifier: identifier)
        }
    }

    // WHY: didChange carries the selected post-mutation preference without a stale store read.
    private func observeAppStateChanges() {
        appStore.didChange
            .sink { [weak self] appState in self?.recompute(from: appState) }
            .store(in: &storeSubscriptions)
    }

    // WHY: the state parameter fixes every displayed setting to the same app-state snapshot.
    private func recompute(from appState: AppState) {
        appearanceOptions = AppearanceTheme.allCases.map(makeAppearanceOption)
        selectedAppearanceIdentifier = appState.appearanceTheme.rawValue
    }

    // WHY: domain choices become primitive package values only at the app boundary.
    private func makeAppearanceOption(appearanceTheme: AppearanceTheme) -> AppearanceOption {
        AppearanceOption(id: appearanceTheme.rawValue, title: appearanceTheme.label)
    }

    // WHY: invalid identifiers from UI state are ignored instead of corrupting the persisted preference.
    private func selectAppearanceTheme(identifier: String) {
        guard let appearanceTheme: AppearanceTheme = AppearanceTheme(rawValue: identifier) else { return }
        appStore.selectAppearanceTheme(appearanceTheme)
    }
}
