import SwiftUI

struct AppRootView: View {
    @ObservedObject var appStore: AppStore

    var body: some View {
        PDFLibraryHost(appStore: appStore)
            .preferredColorScheme(makeColorScheme(appearanceTheme: appStore.state.appearanceTheme))
    }

    // WHY: SwiftUI's ColorScheme remains in the view layer instead of leaking into domain state.
    private func makeColorScheme(appearanceTheme: AppearanceTheme) -> ColorScheme? {
        switch appearanceTheme {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
