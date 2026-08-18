import Foundation

struct AppState {
    var importedPDFFiles: [ImportedPDFFile] = []
    var selectedPDFFileIdentifier: UUID? = nil
    var selectedPDFFileURL: URL? = nil
    var isFileImporterPresented: Bool = false
    var isNightModeEnabled: Bool = false
    var isAllHighlightsRemovalPending: Bool = false
    var appearanceTheme: AppearanceTheme = .system
    var pdfInquiryEntries: [PDFInquiryEntry] = []
    var pdfInquiryPhase: PDFInquiryPhase = .idle
    var pdfInquiryAvailability: PDFInquiryAvailability = .unavailable
    var pdfInquiryRequestIdentifier: UUID? = nil
}
