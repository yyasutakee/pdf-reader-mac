import AppKit
import Combine
import Foundation
import PDFLibraryFeature

@MainActor
final class PDFLibraryViewStore: PDFLibraryViewModel {
    @Published private(set) var items: [PDFLibraryItem] = []
    @Published private(set) var selectedItemIdentifier: UUID? = nil
    @Published private(set) var isFileImporterPresented: Bool = false

    private let appStore: AppStore
    private var storeSubscriptions: Set<AnyCancellable> = []

    init(appStore: AppStore) {
        self.appStore = appStore
        observeAppStateChanges()
        recompute(from: appStore.state)
    }

    // WHY: package events are translated here so the UI package never imports the app domain.
    func send(_ event: PDFLibraryEvent) {
        switch event {
        case .importButtonTapped: appStore.presentFileImporter()
        case .fileImporterDismissed: appStore.dismissFileImporter()
        case .pdfFileSelected(let URL): appStore.importPDFFile(from: URL)
        case .libraryItemSelected(let identifier): appStore.selectPDFFile(identifier: identifier)
        case .libraryItemRevealRequested(let identifier): revealPDFFileInFinder(identifier: identifier)
        case .libraryItemRemovalRequested(let identifier): appStore.removeImportedPDFFile(identifier: identifier)
        }
    }

    // WHY: Finder presentation is app-layer behavior and must not leak into the domain or UI package contract.
    private func revealPDFFileInFinder(identifier: UUID) {
        guard let fileURL: URL = appStore.findStoredPDFFileURL(identifier: identifier) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    // WHY: didChange supplies the post-mutation value required for an accurate display snapshot.
    private func observeAppStateChanges() {
        appStore.didChange
            .sink { [weak self] appState in self?.recompute(from: appState) }
            .store(in: &storeSubscriptions)
    }

    // WHY: taking AppState as input makes stale reads from the store impossible inside the subscriber.
    private func recompute(from appState: AppState) {
        items = appState.importedPDFFiles.map(makeLibraryItem)
        selectedItemIdentifier = appState.selectedPDFFileIdentifier
        isFileImporterPresented = appState.isFileImporterPresented
    }

    // WHY: the app boundary maps persistence-shaped metadata into the feature's display-shaped item.
    private func makeLibraryItem(importedPDFFile: ImportedPDFFile) -> PDFLibraryItem {
        PDFLibraryItem(
            id: importedPDFFile.identifier,
            title: importedPDFFile.displayName,
            thumbnailURL: importedPDFFile.thumbnailFileURLAbsoluteString.flatMap(URL.init(string:)),
            currentPageNumber: importedPDFFile.lastReadPageIndex + 1,
            totalPageCount: importedPDFFile.totalPageCount,
            lastReadDate: importedPDFFile.lastReadDate
        )
    }
}
