import SwiftUI

public struct SettingsView<Model: SettingsViewModel>: View {
    @ObservedObject private var model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        Form {
            Picker("Appearance", selection: selectedAppearanceIdentifier) {
                ForEach(model.appearanceOptions) { option in Text(option.title).tag(option.id) }
            }
            .pickerStyle(.radioGroup)
        }
        .padding()
        .frame(width: 280)
    }

    private var selectedAppearanceIdentifier: Binding<String> {
        Binding(
            get: { model.selectedAppearanceIdentifier },
            set: { model.send(.appearanceSelected($0)) }
        )
    }
}
