import SwiftUI

@main
struct PDFReaderApp: App {
    @StateObject private var appStore: AppStore = AppStore()

    var body: some Scene {
        WindowGroup {
            AppRootView(appStore: appStore)
        }

        Settings {
            SettingsHost(appStore: appStore)
        }
    }
}
