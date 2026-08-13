import SettingsFeature
import SwiftUI

struct SettingsHost: View {
    @StateObject private var viewStore: SettingsViewStore

    init(appStore: AppStore) {
        _viewStore = StateObject(wrappedValue: SettingsViewStore(appStore: appStore))
    }

    var body: some View {
        SettingsView(model: viewStore)
    }
}
