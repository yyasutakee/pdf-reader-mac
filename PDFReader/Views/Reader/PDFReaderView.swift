import SwiftUI
import PDFKit

struct PDFReaderView: NSViewRepresentable {
    let pdfFileURL: URL
    let initialScrollPosition: PDFScrollPosition?
    @Binding var clearAllHighlightsRequested: Bool
    let onScrollPositionChanged: (PDFScrollPosition) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScrollPositionChanged: onScrollPositionChanged)
    }

    func makeNSView(context: Context) -> HighlightablePDFView {
        let pdfView: HighlightablePDFView = HighlightablePDFView()
        let coordinator: Coordinator = context.coordinator
        configureDisplaySettings(pdfView: pdfView)
        loadDocument(pdfView: pdfView)
        scheduleScrollPositionRestoration(pdfView: pdfView)
        registerVisiblePagesObserver(pdfView: pdfView, coordinator: coordinator)
        pdfView.onLiveScroll = { [weak coordinator, weak pdfView] in
            guard let coordinator: Coordinator = coordinator else { return }
            guard let pdfView: HighlightablePDFView = pdfView else { return }
            coordinator.scheduleSavePosition(pdfView: pdfView)
        }
        return pdfView
    }

    func updateNSView(_ nsView: HighlightablePDFView, context: Context) {
        context.coordinator.onScrollPositionChanged = onScrollPositionChanged
        handleClearAllHighlightsRequestIfNeeded(pdfView: nsView)
        handleDocumentChangeIfNeeded(pdfView: nsView)
    }

    private func handleClearAllHighlightsRequestIfNeeded(pdfView: HighlightablePDFView) {
        guard clearAllHighlightsRequested else { return }
        pdfView.clearAllHighlights()
        clearAllHighlightsRequested = false
    }

    private func handleDocumentChangeIfNeeded(pdfView: HighlightablePDFView) {
        guard isDocumentChanged(pdfView: pdfView) else { return }
        reloadDocument(pdfView: pdfView)
        scheduleScrollPositionRestoration(pdfView: pdfView)
    }

    private func scheduleScrollPositionRestoration(pdfView: HighlightablePDFView) {
        let position: PDFScrollPosition? = initialScrollPosition
        DispatchQueue.main.async { pdfView.restorePendingScrollPosition(position) }
    }

    private func configureDisplaySettings(pdfView: HighlightablePDFView) {
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
    }

    private func loadDocument(pdfView: HighlightablePDFView) {
        pdfView.document = PDFDocument(url: pdfFileURL)
    }

    private func registerVisiblePagesObserver(pdfView: HighlightablePDFView, coordinator: Coordinator) {
        NotificationCenter.default.addObserver(
            coordinator,
            selector: #selector(Coordinator.handleVisiblePagesChanged),
            name: .PDFViewVisiblePagesChanged,
            object: pdfView
        )
    }

    private func isDocumentChanged(pdfView: HighlightablePDFView) -> Bool {
        return pdfView.document?.documentURL != pdfFileURL
    }

    private func reloadDocument(pdfView: HighlightablePDFView) {
        pdfView.document = PDFDocument(url: pdfFileURL)
    }

    class Coordinator: NSObject {
        var onScrollPositionChanged: (PDFScrollPosition) -> Void
        private var savePositionTimer: Timer? = nil
        private let savePositionDebounceInterval: Double = 0.5

        init(onScrollPositionChanged: @escaping (PDFScrollPosition) -> Void) {
            self.onScrollPositionChanged = onScrollPositionChanged
        }

        @objc func handleVisiblePagesChanged(_ notification: Notification) {
            guard let pdfView: PDFView = notification.object as? PDFView else { return }
            scheduleSavePosition(pdfView: pdfView)
        }

        func scheduleSavePosition(pdfView: PDFView) {
            cancelPendingTimer()
            savePositionTimer = makeDebounceTimer(pdfView: pdfView)
        }

        private func cancelPendingTimer() {
            savePositionTimer?.invalidate()
            savePositionTimer = nil
        }

        private func makeDebounceTimer(pdfView: PDFView) -> Timer {
            return Timer.scheduledTimer(withTimeInterval: savePositionDebounceInterval, repeats: false) { [weak self] _ in
                self?.saveCurrentPosition(pdfView: pdfView)
            }
        }

        private func saveCurrentPosition(pdfView: PDFView) {
            cancelPendingTimer()
            guard let scrollPosition: PDFScrollPosition = currentScrollPosition(pdfView: pdfView) else { return }
            onScrollPositionChanged(scrollPosition)
        }

        private func currentScrollPosition(pdfView: PDFView) -> PDFScrollPosition? {
            guard let destination: PDFDestination = pdfView.currentDestination else { return nil }
            guard let document: PDFDocument = pdfView.document else { return nil }
            guard let page: PDFPage = destination.page else { return nil }
            return buildScrollPosition(page: page, destination: destination, document: document, zoomScale: pdfView.scaleFactor)
        }

        private func buildScrollPosition(page: PDFPage, destination: PDFDestination, document: PDFDocument, zoomScale: CGFloat) -> PDFScrollPosition {
            return PDFScrollPosition(
                pageIndex: document.index(for: page),
                pagePointX: Double(destination.point.x),
                pagePointY: Double(destination.point.y),
                zoomScale: Double(zoomScale)
            )
        }
    }
}
