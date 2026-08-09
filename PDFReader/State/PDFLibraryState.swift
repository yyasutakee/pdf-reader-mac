import Foundation

struct PDFLibraryState {
    var importedPDFFiles: [ImportedPDFFile]
    var isShowingFilePicker: Bool
    var selectedPDFFile: ImportedPDFFile?
    var selectedPDFFileURL: URL?
    var isNightModeEnabled: Bool

    init(importedPDFFiles: [ImportedPDFFile] = []) {
        self.importedPDFFiles = importedPDFFiles
        self.isShowingFilePicker = false
        self.selectedPDFFile = nil
        self.selectedPDFFileURL = nil
        self.isNightModeEnabled = false
    }
}
