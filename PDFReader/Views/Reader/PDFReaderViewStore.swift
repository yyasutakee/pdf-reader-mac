import Combine
import Foundation
import PDFReaderFeature

@MainActor
final class PDFReaderViewStore: PDFReaderViewModel {
    @Published private(set) var documentURL: URL? = nil
    @Published private(set) var initialPosition: PDFReaderPosition? = nil
    @Published private(set) var isNightModeEnabled: Bool = false
    @Published private(set) var isAllHighlightsRemovalPending: Bool = false
    @Published private(set) var currentPageIndex: Int? = nil
    @Published private(set) var bookmarks: [PDFBookmarkItem] = []
    @Published private(set) var isCurrentPageBookmarked: Bool = false
    @Published private(set) var bookmarkNavigationPageIndex: Int? = nil

    private let appStore: AppStore
    private var storeSubscriptions: Set<AnyCancellable> = []
    private var selectedPDFFileIdentifier: UUID? = nil

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
        case .currentPageChanged(let pageIndex): setCurrentPageIndex(pageIndex)
        case .currentPageBookmarkToggled: toggleCurrentPageBookmark()
        case .bookmarkSelected(let pageIndex): setBookmarkNavigationPageIndex(pageIndex)
        case .bookmarkRemoved(let pageIndex): appStore.removeBookmark(pageIndex: pageIndex)
        case .bookmarkNavigationHandled: setBookmarkNavigationPageIndex(nil)
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
        updateSelectedPDFFile(appState: appState)
        bookmarks = makeBookmarkItems(appState: appState)
        isCurrentPageBookmarked = calculateIsCurrentPageBookmarked(bookmarks: bookmarks, currentPageIndex: currentPageIndex)
    }

    // WHY: switching documents resets page-local presentation state before new PDFKit callbacks arrive.
    private func updateSelectedPDFFile(appState: AppState) {
        guard selectedPDFFileIdentifier != appState.selectedPDFFileIdentifier else { return }
        selectedPDFFileIdentifier = appState.selectedPDFFileIdentifier
        currentPageIndex = makeSelectedPageIndex(appState: appState)
        bookmarkNavigationPageIndex = nil
    }

    // WHY: immediate page publication keeps toolbar status synchronized while position persistence remains debounced.
    private func setCurrentPageIndex(_ pageIndex: Int) {
        currentPageIndex = pageIndex
        isCurrentPageBookmarked = calculateIsCurrentPageBookmarked(bookmarks: bookmarks, currentPageIndex: pageIndex)
    }

    // WHY: the package navigation request is retained only until PDFKit acknowledges handling it.
    private func setBookmarkNavigationPageIndex(_ pageIndex: Int?) {
        bookmarkNavigationPageIndex = pageIndex
    }

    // WHY: the current page is required before bookmark intent can be forwarded to persistent domain state.
    private func toggleCurrentPageBookmark() {
        guard let currentPageIndex else { return }
        appStore.toggleBookmark(pageIndex: currentPageIndex)
    }

    // WHY: the selected document's persisted pages become display-only inspector rows at the app boundary.
    private func makeBookmarkItems(appState: AppState) -> [PDFBookmarkItem] {
        guard let importedPDFFile: ImportedPDFFile = findSelectedPDFFile(appState: appState) else { return [] }
        return importedPDFFile.bookmarkedPageIndices.filter { $0 >= 0 }.sorted().map(PDFBookmarkItem.init(pageIndex:))
    }

    // WHY: bookmark fill state is derived from the same rows shown by the inspector.
    private func calculateIsCurrentPageBookmarked(bookmarks: [PDFBookmarkItem], currentPageIndex: Int?) -> Bool {
        guard let currentPageIndex else { return false }
        return bookmarks.contains { $0.pageIndex == currentPageIndex }
    }

    // WHY: initial toolbar state uses the saved page until PDFKit reports its actual destination.
    private func makeSelectedPageIndex(appState: AppState) -> Int? {
        findSelectedPDFFile(appState: appState)?.lastReadPageIndex
    }

    // WHY: selected-file lookup has one definition for position and bookmark mappings.
    private func findSelectedPDFFile(appState: AppState) -> ImportedPDFFile? {
        guard let identifier: UUID = appState.selectedPDFFileIdentifier else { return nil }
        return appState.importedPDFFiles.first { $0.identifier == identifier }
    }

    // WHY: the selected identifier is resolved to its saved position without exposing the domain item.
    private func makeReaderPosition(appState: AppState) -> PDFReaderPosition? {
        findSelectedPDFFile(appState: appState)?.lastReadScrollPosition.map(makeReaderPosition)
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
