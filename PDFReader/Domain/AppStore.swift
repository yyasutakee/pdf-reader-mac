import Foundation
import PDFKit

final class AppStore: Store<AppState> {
    private let pdfLibraryRepository: PDFLibraryRepository
    private let pdfFileStorageService: PDFFileStorageService
    private let pdfThumbnailService: PDFThumbnailService
    private let pdfThumbnailRepository: PDFThumbnailRepository
    private let appearanceRepository: AppearanceRepository

    init(
        pdfLibraryRepository: PDFLibraryRepository = PDFLibraryRepository(),
        pdfFileStorageService: PDFFileStorageService = PDFFileStorageService(),
        pdfThumbnailService: PDFThumbnailService = PDFThumbnailService(),
        pdfThumbnailRepository: PDFThumbnailRepository = PDFThumbnailRepository(),
        appearanceRepository: AppearanceRepository = AppearanceRepository()
    ) {
        self.pdfLibraryRepository = pdfLibraryRepository
        self.pdfFileStorageService = pdfFileStorageService
        self.pdfThumbnailService = pdfThumbnailService
        self.pdfThumbnailRepository = pdfThumbnailRepository
        self.appearanceRepository = appearanceRepository
        super.init(initialState: AppState(
            importedPDFFiles: pdfLibraryRepository.loadSavedPDFFiles(),
            appearanceTheme: appearanceRepository.loadAppearanceTheme()
        ))
    }

    // WHY: the import picker is app navigation state coordinated through the single state tree.
    func presentFileImporter() {
        setState { $0.isFileImporterPresented = true }
    }

    // WHY: cancellation and completion both return importer presentation to its resting state.
    func dismissFileImporter() {
        setState { $0.isFileImporterPresented = false }
    }

    // WHY: importing owns security-scoped access and every persistence write behind the store boundary.
    func importPDFFile(from sourceURL: URL) {
        let isAccessGranted: Bool = sourceURL.startAccessingSecurityScopedResource()
        defer { sourceURL.stopAccessingSecurityScopedResource() }
        print("[AppStore] startAccessingSecurityScopedResource: \(isAccessGranted)")
        guard let importedPDFFile: ImportedPDFFile = makeImportedPDFFile(sourceURL: sourceURL) else { return }
        setState { appState in
            appState.importedPDFFiles.append(importedPDFFile)
            appState.isFileImporterPresented = false
        }
        persistImportedPDFFiles()
    }

    // WHY: selection resolves the app-owned filename into the concrete URL needed by observers.
    func selectPDFFile(identifier: UUID?) {
        guard let identifier else { deselectPDFFile(); return }
        guard let importedPDFFile: ImportedPDFFile = findImportedPDFFile(identifier: identifier) else { return }
        let fileURL: URL? = pdfFileStorageService.resolveStoredFileURL(storedFileName: importedPDFFile.storedFileName)
        setState { appState in
            appState.selectedPDFFileIdentifier = identifier
            appState.selectedPDFFileURL = fileURL
            appState.isAllHighlightsRemovalPending = false
        }
    }

    // WHY: an empty library selection must clear every value derived from the previous document.
    func deselectPDFFile() {
        setState { appState in
            appState.selectedPDFFileIdentifier = nil
            appState.selectedPDFFileURL = nil
            appState.isAllHighlightsRemovalPending = false
        }
    }

    // WHY: removal coordinates the stored PDF, cached thumbnail, metadata, and active selection atomically.
    func removeImportedPDFFile(identifier: UUID) {
        guard let importedPDFFile: ImportedPDFFile = findImportedPDFFile(identifier: identifier) else { return }
        pdfFileStorageService.deleteStoredFile(storedFileName: importedPDFFile.storedFileName)
        pdfThumbnailRepository.deleteThumbnail(for: identifier)
        setState { removeImportedPDFFile(identifier: identifier, from: &$0) }
        persistImportedPDFFiles()
    }

    // WHY: the reading position is persisted so reopening a document resumes at the last known destination.
    func saveReadingPosition(_ position: PDFScrollPosition) {
        guard let identifier: UUID = state.selectedPDFFileIdentifier else { return }
        setState { updateReadingPosition(position, identifier: identifier, in: &$0) }
        persistImportedPDFFiles()
    }

    // WHY: night mode is temporary reader state shared with the package through its view store.
    func toggleNightMode() {
        setState { $0.isNightModeEnabled.toggle() }
    }

    // WHY: highlight removal is modeled as a command state until the retained PDFKit view acknowledges it.
    func requestAllHighlightsRemoval() {
        setState { $0.isAllHighlightsRemovalPending = true }
    }

    // WHY: acknowledgment prevents SwiftUI updates from repeating a completed destructive command.
    func finishAllHighlightsRemoval() {
        setState { $0.isAllHighlightsRemovalPending = false }
    }

    // WHY: appearance selection is persisted by the store so Settings never touches UserDefaults directly.
    func selectAppearanceTheme(_ appearanceTheme: AppearanceTheme) {
        appearanceRepository.persistAppearanceTheme(appearanceTheme)
        setState { $0.appearanceTheme = appearanceTheme }
    }

    // WHY: import construction groups file copying and metadata derivation behind one failure boundary.
    private func makeImportedPDFFile(sourceURL: URL) -> ImportedPDFFile? {
        guard let storedFileName: String = pdfFileStorageService.copyPDFFileIntoStorage(from: sourceURL) else { return nil }
        let identifier: UUID = UUID()
        let storedFileURL: URL? = pdfFileStorageService.resolveStoredFileURL(storedFileName: storedFileName)
        return ImportedPDFFile(
            identifier: identifier,
            displayName: sourceURL.deletingPathExtension().lastPathComponent,
            storedFileName: storedFileName,
            thumbnailFileURLAbsoluteString: makeThumbnailURLString(storedFileURL: storedFileURL, identifier: identifier),
            importedDate: Date(),
            totalPageCount: makePageCount(storedFileURL: storedFileURL)
        )
    }

    // WHY: thumbnail generation is optional metadata and must not fail the PDF import itself.
    private func makeThumbnailURLString(storedFileURL: URL?, identifier: UUID) -> String? {
        guard let storedFileURL else { return nil }
        let image = pdfThumbnailService.generateFirstPageThumbnail(for: storedFileURL, thumbnailSize: CGSize(width: 160, height: 220))
        return image.flatMap { pdfThumbnailRepository.saveThumbnail($0, for: identifier) }?.absoluteString
    }

    // WHY: page count is derived once during import to keep library progress rendering lightweight.
    private func makePageCount(storedFileURL: URL?) -> Int? {
        guard let storedFileURL else { return nil }
        return PDFDocument(url: storedFileURL)?.pageCount
    }

    // WHY: identifier lookup has one definition for selection and destructive operations.
    private func findImportedPDFFile(identifier: UUID) -> ImportedPDFFile? {
        state.importedPDFFiles.first { $0.identifier == identifier }
    }

    // WHY: removal also clears values derived from the deleted selection in the same mutation.
    private func removeImportedPDFFile(identifier: UUID, from appState: inout AppState) {
        appState.importedPDFFiles.removeAll { $0.identifier == identifier }
        guard appState.selectedPDFFileIdentifier == identifier else { return }
        appState.selectedPDFFileIdentifier = nil
        appState.selectedPDFFileURL = nil
        appState.isAllHighlightsRemovalPending = false
    }

    // WHY: one mutation keeps persisted progress and the selected document snapshot identical.
    private func updateReadingPosition(_ position: PDFScrollPosition, identifier: UUID, in appState: inout AppState) {
        guard let index: Int = appState.importedPDFFiles.firstIndex(where: { $0.identifier == identifier }) else { return }
        appState.importedPDFFiles[index].lastReadPageIndex = position.pageIndex
        appState.importedPDFFiles[index].lastReadScrollPosition = position
        appState.importedPDFFiles[index].lastReadDate = Date()
    }

    // WHY: every metadata mutation is encoded from the post-mutation state through one persistence call.
    private func persistImportedPDFFiles() {
        pdfLibraryRepository.persistPDFFiles(state.importedPDFFiles)
    }
}
