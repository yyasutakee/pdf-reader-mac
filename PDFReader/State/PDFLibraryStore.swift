import Foundation
import PDFKit

class PDFLibraryStore: Store<PDFLibraryState> {
    private let pdfLibraryRepository: PDFLibraryRepository
    private let pdfFileStorageService: PDFFileStorageService
    private let pdfThumbnailService: PDFThumbnailService
    private let pdfThumbnailRepository: PDFThumbnailRepository

    init(
        pdfLibraryRepository: PDFLibraryRepository,
        pdfFileStorageService: PDFFileStorageService,
        pdfThumbnailService: PDFThumbnailService,
        pdfThumbnailRepository: PDFThumbnailRepository
    ) {
        self.pdfLibraryRepository = pdfLibraryRepository
        self.pdfFileStorageService = pdfFileStorageService
        self.pdfThumbnailService = pdfThumbnailService
        self.pdfThumbnailRepository = pdfThumbnailRepository
        super.init(initialState: PDFLibraryState(
            importedPDFFiles: pdfLibraryRepository.loadSavedPDFFiles()
        ))
    }

    func presentFilePicker() {
        setState { $0.isShowingFilePicker = true }
    }

    func dismissFilePicker() {
        setState { $0.isShowingFilePicker = false }
    }

    func selectPDFFile(_ importedPDFFile: ImportedPDFFile) {
        let resolvedFileURL = pdfFileStorageService.resolveStoredFileURL(
            storedFileName: importedPDFFile.storedFileName
        )
        setState {
            $0.selectedPDFFile = importedPDFFile
            $0.selectedPDFFileURL = resolvedFileURL
        }
    }

    func deselectPDFFile() {
        setState {
            $0.selectedPDFFile = nil
            $0.selectedPDFFileURL = nil
        }
    }

    func toggleNightMode() {
        setState { $0.isNightModeEnabled.toggle() }
    }

    func saveScrollPosition(scrollPosition: PDFScrollPosition, for importedPDFFile: ImportedPDFFile) {
        setState { updateScrollPosition(scrollPosition: scrollPosition, for: importedPDFFile, in: &$0) }
        pdfLibraryRepository.persistPDFFiles(state.importedPDFFiles)
    }

    func importPDFFile(from fileURL: URL) {
        let isAccessGranted = fileURL.startAccessingSecurityScopedResource()
        defer { fileURL.stopAccessingSecurityScopedResource() }
        print("[PDFLibraryStore] startAccessingSecurityScopedResource: \(isAccessGranted)")

        guard let storedFileName = pdfFileStorageService.copyPDFFileIntoStorage(from: fileURL) else {
            print("[PDFLibraryStore] failed to copy PDF into storage")
            return
        }

        let newPDFFileIdentifier = UUID()
        var thumbnailFileURLAbsoluteString: String? = nil
        var totalPageCount: Int? = nil

        if let storedFileURL = pdfFileStorageService.resolveStoredFileURL(storedFileName: storedFileName) {
            if let pdfDocument = PDFDocument(url: storedFileURL) {
                totalPageCount = pdfDocument.pageCount
            }
            let thumbnailImage = pdfThumbnailService.generateFirstPageThumbnail(
                for: storedFileURL,
                thumbnailSize: CGSize(width: 160, height: 220)
            )
            thumbnailFileURLAbsoluteString = thumbnailImage.flatMap {
                pdfThumbnailRepository.saveThumbnail($0, for: newPDFFileIdentifier)
            }?.absoluteString
        }

        let newImportedPDFFile = ImportedPDFFile(
            identifier: newPDFFileIdentifier,
            displayName: fileURL.deletingPathExtension().lastPathComponent,
            storedFileName: storedFileName,
            thumbnailFileURLAbsoluteString: thumbnailFileURLAbsoluteString,
            importedDate: Date(),
            totalPageCount: totalPageCount
        )
        setState { $0.importedPDFFiles.append(newImportedPDFFile) }
        pdfLibraryRepository.persistPDFFiles(state.importedPDFFiles)
    }

    func removeImportedPDFFile(_ importedPDFFile: ImportedPDFFile) {
        pdfFileStorageService.deleteStoredFile(storedFileName: importedPDFFile.storedFileName)
        pdfThumbnailRepository.deleteThumbnail(for: importedPDFFile.identifier)
        setState { state in
            state.importedPDFFiles.removeAll { $0.identifier == importedPDFFile.identifier }
            if state.selectedPDFFile?.identifier == importedPDFFile.identifier {
                state.selectedPDFFile = nil
                state.selectedPDFFileURL = nil
            }
        }
        pdfLibraryRepository.persistPDFFiles(state.importedPDFFiles)
    }

    private func updateScrollPosition(scrollPosition: PDFScrollPosition, for importedPDFFile: ImportedPDFFile, in state: inout PDFLibraryState) {
        guard let listIndex: Int = state.importedPDFFiles.firstIndex(where: { $0.identifier == importedPDFFile.identifier }) else { return }
        state.importedPDFFiles[listIndex].lastReadPageIndex = scrollPosition.pageIndex
        state.importedPDFFiles[listIndex].lastReadScrollPosition = scrollPosition
        state.importedPDFFiles[listIndex].lastReadDate = Date()
        updateSelectedFileIfNeeded(scrollPosition: scrollPosition, for: importedPDFFile, in: &state)
    }

    private func updateSelectedFileIfNeeded(scrollPosition: PDFScrollPosition, for importedPDFFile: ImportedPDFFile, in state: inout PDFLibraryState) {
        guard state.selectedPDFFile?.identifier == importedPDFFile.identifier else { return }
        state.selectedPDFFile?.lastReadPageIndex = scrollPosition.pageIndex
        state.selectedPDFFile?.lastReadScrollPosition = scrollPosition
        state.selectedPDFFile?.lastReadDate = Date()
    }
}
