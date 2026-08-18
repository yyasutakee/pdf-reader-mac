import Foundation

struct PDFAnswerConfigurationRepository {
    private let providerStorageKey: String = "pdfAnswerProvider"
    private let codexExecutablePathStorageKey: String = "codexExecutablePath"

    // WHY: launch restores the selected answer provider without coupling domain state to UserDefaults.
    func loadPDFAnswerProvider() -> PDFAnswerProvider {
        guard let rawValue: String = UserDefaults.standard.string(forKey: providerStorageKey) else { return .appleIntelligence }
        return PDFAnswerProvider(rawValue: rawValue) ?? .appleIntelligence
    }

    // WHY: provider selection must survive relaunch because its prerequisites differ between machines.
    func persistPDFAnswerProvider(_ provider: PDFAnswerProvider) {
        UserDefaults.standard.set(provider.rawValue, forKey: providerStorageKey)
    }

    // WHY: GUI apps do not inherit the interactive shell PATH, so the verified executable location is persisted explicitly.
    func loadCodexExecutablePath() -> String {
        UserDefaults.standard.string(forKey: codexExecutablePathStorageKey) ?? ""
    }

    // WHY: path edits must be retained independently from the selected provider.
    func persistCodexExecutablePath(_ executablePath: String) {
        UserDefaults.standard.set(executablePath, forKey: codexExecutablePathStorageKey)
    }
}
