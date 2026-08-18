import SwiftUI

public struct SettingsView<Model: SettingsViewModel>: View {
    @ObservedObject private var model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        Form {
            appearanceSection
            pdfAnswerSection
        }
        .formStyle(.grouped)
        .frame(width: 440)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: selectedAppearanceIdentifier) {
                ForEach(model.appearanceOptions) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .pickerStyle(.radioGroup)
        }
    }

    private var pdfAnswerSection: some View {
        Section("AI Answers") {
            Picker("Provider", selection: selectedPDFAnswerProviderIdentifier) {
                ForEach(model.pdfAnswerProviderOptions) { option in
                    Text(option.title).tag(option.id)
                }
            }
            if model.showsCodexExecutablePath {
                TextField("Codex executable path", text: codexExecutablePath)
                Text("Enter an absolute path such as /opt/homebrew/bin/codex. Run codex login in Terminal first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Only text extracted from the page range you choose is sent to the selected AI provider.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var selectedAppearanceIdentifier: Binding<String> {
        Binding(
            get: { model.selectedAppearanceIdentifier },
            set: { model.send(.appearanceSelected($0)) }
        )
    }

    private var selectedPDFAnswerProviderIdentifier: Binding<String> {
        Binding(
            get: { model.selectedPDFAnswerProviderIdentifier },
            set: { model.send(.pdfAnswerProviderSelected($0)) }
        )
    }

    private var codexExecutablePath: Binding<String> {
        Binding(
            get: { model.codexExecutablePath },
            set: { model.send(.codexExecutablePathChanged($0)) }
        )
    }
}
