import PDFKit
import SwiftUI

struct PDFDocumentView: NSViewRepresentable {
    let documentURL: URL
    let initialPosition: PDFReaderPosition?
    let isAllHighlightsRemovalPending: Bool
    let bookmarkNavigationPageIndex: Int?
    let onEvent: (PDFReaderEvent) -> Void

    // WHY: the coordinator owns debouncing state that must survive representable updates.
    func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }

    // WHY: PDFKit rendering requires one configured AppKit view behind the SwiftUI boundary.
    func makeNSView(context: Context) -> HighlightablePDFView {
        let pdfView: HighlightablePDFView = makeConfiguredPDFView()
        connectPositionObservation(pdfView: pdfView, coordinator: context.coordinator)
        return pdfView
    }

    // WHY: SwiftUI updates carry document changes and one-shot commands into the retained PDFKit view.
    func updateNSView(_ pdfView: HighlightablePDFView, context: Context) {
        context.coordinator.setEventHandler(onEvent)
        handleAllHighlightsRemovalIfNeeded(pdfView: pdfView)
        handleDocumentChangeIfNeeded(pdfView: pdfView)
        handleBookmarkNavigationIfNeeded(pdfView: pdfView)
    }

    // WHY: construction is separated so makeNSView remains a readable composition sequence.
    private func makeConfiguredPDFView() -> HighlightablePDFView {
        let pdfView: HighlightablePDFView = HighlightablePDFView()
        configureDisplay(pdfView: pdfView)
        loadDocument(pdfView: pdfView)
        schedulePositionRestoration(pdfView: pdfView)
        return pdfView
    }

    // WHY: these PDFKit settings define the reader's continuous vertical presentation.
    private func configureDisplay(pdfView: HighlightablePDFView) {
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
    }

    // WHY: document loading stays inside the UI package because the URL is the package's display input.
    private func loadDocument(pdfView: HighlightablePDFView) {
        pdfView.document = PDFDocument(url: documentURL)
    }

    // WHY: PDFKit must finish layout before it can navigate to the restored page point.
    private func schedulePositionRestoration(pdfView: HighlightablePDFView) {
        let position: PDFReaderPosition? = initialPosition
        DispatchQueue.main.async { pdfView.restorePendingPosition(position) }
    }

    // WHY: both PDFKit page notifications and live scrolling feed one debounced position stream.
    private func connectPositionObservation(pdfView: HighlightablePDFView, coordinator: Coordinator) {
        registerVisiblePagesObserver(pdfView: pdfView, coordinator: coordinator)
        pdfView.onLiveScroll = { [weak coordinator, weak pdfView] in coordinator?.schedulePositionCapture(pdfView: pdfView) }
    }

    // WHY: PDFKit exposes page movement through a notification rather than a delegate callback.
    private func registerVisiblePagesObserver(pdfView: HighlightablePDFView, coordinator: Coordinator) {
        NotificationCenter.default.addObserver(
            coordinator,
            selector: #selector(Coordinator.handleVisiblePagesChanged),
            name: .PDFViewVisiblePagesChanged,
            object: pdfView
        )
    }

    // WHY: clearing is a one-shot command whose completion must be acknowledged to the model.
    private func handleAllHighlightsRemovalIfNeeded(pdfView: HighlightablePDFView) {
        guard isAllHighlightsRemovalPending else { return }
        pdfView.removeAllHighlights()
        onEvent(.allHighlightsRemovalHandled)
    }

    // WHY: the retained AppKit view must replace its PDFDocument when the selected URL changes.
    private func handleDocumentChangeIfNeeded(pdfView: HighlightablePDFView) {
        guard pdfView.document?.documentURL != documentURL else { return }
        loadDocument(pdfView: pdfView)
        schedulePositionRestoration(pdfView: pdfView)
    }

    // WHY: bookmark selection is a one-shot navigation request acknowledged after PDFKit receives it.
    private func handleBookmarkNavigationIfNeeded(pdfView: HighlightablePDFView) {
        guard let pageIndex: Int = bookmarkNavigationPageIndex else { return }
        pdfView.navigateToPage(pageIndex: pageIndex)
        DispatchQueue.main.async { onEvent(.bookmarkNavigationHandled) }
    }

    final class Coordinator: NSObject {
        private var onEvent: (PDFReaderEvent) -> Void
        private var captureTimer: Timer?
        private let captureDebounceInterval: Double = 0.5

        init(onEvent: @escaping (PDFReaderEvent) -> Void) {
            self.onEvent = onEvent
        }

        // WHY: SwiftUI can replace a closure while retaining the coordinator instance.
        func setEventHandler(_ onEvent: @escaping (PDFReaderEvent) -> Void) {
            self.onEvent = onEvent
        }

        // WHY: visible-page changes must join live scrolling in the same debounced capture path.
        @objc func handleVisiblePagesChanged(_ notification: Notification) {
            let pdfView: PDFView? = notification.object as? PDFView
            publishCurrentPage(pdfView: pdfView)
            schedulePositionCapture(pdfView: pdfView)
        }

        // WHY: the toolbar bookmark state must track page changes immediately rather than after persistence debounce.
        private func publishCurrentPage(pdfView: PDFView?) {
            guard let pdfView else { return }
            guard let document: PDFDocument = pdfView.document else { return }
            guard let page: PDFPage = pdfView.currentDestination?.page else { return }
            onEvent(.currentPageChanged(document.index(for: page)))
        }

        // WHY: frequent PDFKit movement callbacks are coalesced to avoid excessive persistence writes.
        func schedulePositionCapture(pdfView: PDFView?) {
            cancelPendingCapture()
            guard let pdfView else { return }
            captureTimer = makeCaptureTimer(pdfView: pdfView)
        }

        // WHY: one cancellation point prevents stale timers from publishing older positions.
        private func cancelPendingCapture() {
            captureTimer?.invalidate()
            captureTimer = nil
        }

        // WHY: delayed capture waits for movement to settle before deriving the current destination.
        private func makeCaptureTimer(pdfView: PDFView) -> Timer {
            Timer.scheduledTimer(withTimeInterval: captureDebounceInterval, repeats: false) { [weak self] _ in
                self?.publishCurrentPosition(pdfView: pdfView)
            }
        }

        // WHY: position conversion is kept outside the timer plumbing so each method has one responsibility.
        private func publishCurrentPosition(pdfView: PDFView) {
            cancelPendingCapture()
            guard let position: PDFReaderPosition = makeCurrentPosition(pdfView: pdfView) else { return }
            onEvent(.positionChanged(position))
        }

        // WHY: PDFKit objects are translated into the package's display-shaped position value at its boundary.
        private func makeCurrentPosition(pdfView: PDFView) -> PDFReaderPosition? {
            guard let destination: PDFDestination = pdfView.currentDestination else { return nil }
            guard let document: PDFDocument = pdfView.document else { return nil }
            guard let page: PDFPage = destination.page else { return nil }
            return makePosition(page: page, destination: destination, document: document, zoomScale: pdfView.scaleFactor)
        }

        // WHY: the value constructor isolates PDFKit coordinate extraction from observation behavior.
        private func makePosition(page: PDFPage, destination: PDFDestination, document: PDFDocument, zoomScale: CGFloat) -> PDFReaderPosition {
            PDFReaderPosition(
                pageIndex: document.index(for: page),
                pagePointX: Double(destination.point.x),
                pagePointY: Double(destination.point.y),
                zoomScale: Double(zoomScale)
            )
        }
    }
}
