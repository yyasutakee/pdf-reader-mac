import Combine

@MainActor
public protocol SettingsViewModel: ObservableObject {
    var appearanceOptions: [AppearanceOption] { get }
    var selectedAppearanceIdentifier: String { get }
    var pdfAnswerProviderOptions: [PDFAnswerProviderOptionData] { get }
    var selectedPDFAnswerProviderIdentifier: String { get }
    var codexExecutablePath: String { get }
    var showsCodexExecutablePath: Bool { get }

    // WHY: selection intent crosses the package boundary without exposing app-owned implementation details.
    func send(_ event: SettingsEvent)
}
