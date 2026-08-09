import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceTheme") private var appearanceTheme: AppearanceTheme = .system

    var body: some View {
        Form {
            Picker("Appearance", selection: $appearanceTheme) {
                ForEach(AppearanceTheme.allCases, id: \.self) { theme in
                    Text(theme.label).tag(theme)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .padding()
        .frame(width: 280)
    }
}
