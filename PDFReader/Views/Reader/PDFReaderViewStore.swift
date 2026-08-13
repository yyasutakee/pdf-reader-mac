import Combine
import PDFReaderFeature

@MainActor
final class PDFReaderViewStore: PDFReaderViewModel {
    @Published private(set) var documentURL: URL? = nil
    @Published private(set) var initialPosition: PDFReaderPosition? = nil
    @Published private(set) var isNightModeEnabled: Bool = false
    @Published private(set) var isAllHighlightsRemovalPending: Bool = false

    private let appStore: AppStore
    private var storeSubscriptions: Set<AnyCancellable> = []

    init(appStore: AppStore) {
        self.appStore = appStore
        observeAppStateChanges()
        recompute(from: appStore.state)
    }

    // WHY: reader gestures become domain actions only at the app-owned package boundary.
    func send(_ event: PDFReaderEvent) {
        switch event {
        case .nightModeToggled: appStore.toggleNightMode()
        case .allHighlightsRemovalRequested: appStore.requestAllHighlightsRemoval()
        case .allHighlightsRemovalHandled: appStore.finishAllHighlightsRemoval()
        case .positionChanged(let position): appStore.saveReadingPosition(makeDomainPosition(position))
        }
    }

    // WHY: didChange supplies the post-mutation state needed by this manual Combine bridge.
    private func observeAppStateChanges() {
        appStore.didChange
            .sink { [weak self] appState in self?.recompute(from: appState) }
            .store(in: &storeSubscriptions)
    }

    // WHY: the state parameter prevents the subscriber from reading a different app-state moment.
    private func recompute(from appState: AppState) {
        documentURL = appState.selectedPDFFileURL
        initialPosition = makeReaderPosition(appState: appState)
        isNightModeEnabled = appState.isNightModeEnabled
        isAllHighlightsRemovalPending = appState.isAllHighlightsRemovalPending
    }

    // WHY: the selected identifier is resolved to its saved position without exposing the domain item.
    private func makeReaderPosition(appState: AppState) -> PDFReaderPosition? {
        guard let identifier: UUID = appState.selectedPDFFileIdentifier else { return nil }
        let importedPDFFile: ImportedPDFFile? = appState.importedPDFFiles.first { $0.identifier == identifier }
        return importedPDFFile?.lastReadScrollPosition.map(makeReaderPosition)
    }

    // WHY: the app boundary translates persisted coordinates into the feature-owned value type.
    private func makeReaderPosition(domainPosition: PDFScrollPosition) -> PDFReaderPosition {
        PDFReaderPosition(
            pageIndex: domainPosition.pageIndex,
            pagePointX: domainPosition.pagePointX,
            pagePointY: domainPosition.pagePointY,
            zoomScale: domainPosition.zoomScale
        )
    }

    // WHY: the reverse mapping keeps the package's display type out of persistence metadata.
    private func makeDomainPosition(_ readerPosition: PDFReaderPosition) -> PDFScrollPosition {
        PDFScrollPosition(
            pageIndex: readerPosition.pageIndex,
            pagePointX: readerPosition.pagePointX,
            pagePointY: readerPosition.pagePointY,
            zoomScale: readerPosition.zoomScale
        )
    }
}
