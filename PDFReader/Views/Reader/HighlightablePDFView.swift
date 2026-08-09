import PDFKit
import AppKit

final class HighlightablePDFView: PDFView {
    private let highlightService: PDFHighlightService = PDFHighlightService()
    private var annotationPendingRemoval: PDFAnnotation? = nil
    private var pagePendingRemoval: PDFPage? = nil
    var onLiveScroll: (() -> Void)? = nil
    var pendingScrollPosition: PDFScrollPosition? = nil

    override func layout() {
        super.layout()
        navigateToPendingScrollPositionIfNeeded()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        registerClipViewBoundsObserver()
    }

    func restorePendingScrollPosition(_ position: PDFScrollPosition?) {
        pendingScrollPosition = position
        navigateToPendingScrollPositionIfNeeded()
    }

    private func navigateToPendingScrollPositionIfNeeded() {
        guard let position: PDFScrollPosition = pendingScrollPosition else { return }
        guard let destination: PDFDestination = buildDestination(scrollPosition: position) else { return }
        pendingScrollPosition = nil
        go(to: destination)
    }

    private func buildDestination(scrollPosition: PDFScrollPosition) -> PDFDestination? {
        guard let document: PDFDocument = self.document else { return nil }
        guard scrollPosition.pageIndex < document.pageCount else { return nil }
        guard let page: PDFPage = document.page(at: scrollPosition.pageIndex) else { return nil }
        return PDFDestination(page: page, at: CGPoint(x: scrollPosition.pagePointX, y: scrollPosition.pagePointY))
    }

    private func registerClipViewBoundsObserver() {
        guard let clipView: NSClipView = documentView?.enclosingScrollView?.contentView else { return }
        clipView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleClipViewBoundsChanged), name: NSView.boundsDidChangeNotification, object: clipView)
    }

    @objc private func handleClipViewBoundsChanged() {
        onLiveScroll?()
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        if let result: (annotation: PDFAnnotation, page: PDFPage) = highlightAnnotation(windowPoint: event.locationInWindow) {
            return menuWithRemoveOption(annotation: result.annotation, page: result.page)
        }
        guard hasActiveTextSelection else { return super.menu(for: event) }
        return menuWithHighlightOption(baseMenu: super.menu(for: event))
    }

    func clearAllHighlights() {
        guard let document: PDFDocument = self.document else { return }
        highlightService.removeAllHighlights(document: document)
        layoutDocumentView()
        persistDocument(document: document)
    }

    // MARK: - Highlight annotation detection

    private func highlightAnnotation(windowPoint: NSPoint) -> (annotation: PDFAnnotation, page: PDFPage)? {
        let viewPoint: NSPoint = convert(windowPoint, from: nil)
        guard let page: PDFPage = page(for: viewPoint, nearest: false) else { return nil }
        let pagePoint: NSPoint = convert(viewPoint, to: page)
        guard let annotation: PDFAnnotation = highlightAnnotationAtPoint(page: page, pagePoint: pagePoint) else { return nil }
        return (annotation, page)
    }

    private func highlightAnnotationAtPoint(page: PDFPage, pagePoint: NSPoint) -> PDFAnnotation? {
        let annotations: [PDFAnnotation] = page.annotations.filter { PDFHighlightService.isHighlightAnnotation(annotation: $0) }
        return annotations.first { $0.bounds.contains(pagePoint) }
    }

    // MARK: - Add highlight menu

    private var hasActiveTextSelection: Bool {
        return currentSelection?.string?.isEmpty == false
    }

    private func menuWithHighlightOption(baseMenu: NSMenu?) -> NSMenu {
        let menu: NSMenu = baseMenu ?? NSMenu()
        let highlightItem: NSMenuItem = NSMenuItem(title: "Highlight", action: nil, keyEquivalent: "")
        highlightItem.submenu = highlightSubmenu
        menu.insertItem(highlightItem, at: 0)
        menu.insertItem(.separator(), at: 1)
        return menu
    }

    private var highlightSubmenu: NSMenu {
        let submenu: NSMenu = NSMenu(title: "Highlight")
        submenu.addItem(makeMenuItem(title: "Blue", action: #selector(applyBlueHighlight)))
        submenu.addItem(makeMenuItem(title: "Purple", action: #selector(applyPurpleHighlight)))
        submenu.addItem(makeMenuItem(title: "Pink", action: #selector(applyPinkHighlight)))
        submenu.addItem(makeMenuItem(title: "Orange", action: #selector(applyOrangeHighlight)))
        submenu.addItem(makeMenuItem(title: "Yellow", action: #selector(applyYellowHighlight)))
        submenu.addItem(makeMenuItem(title: "Green", action: #selector(applyGreenHighlight)))
        return submenu
    }

    @objc private func applyBlueHighlight() {
        applyHighlight(color: .systemBlue)
    }

    @objc private func applyPurpleHighlight() {
        applyHighlight(color: .systemPurple)
    }

    @objc private func applyPinkHighlight() {
        applyHighlight(color: .systemPink)
    }

    @objc private func applyOrangeHighlight() {
        applyHighlight(color: .systemOrange)
    }

    @objc private func applyYellowHighlight() {
        applyHighlight(color: .systemYellow)
    }

    @objc private func applyGreenHighlight() {
        applyHighlight(color: .systemGreen)
    }

    private func applyHighlight(color: NSColor) {
        guard let selection: PDFSelection = currentSelection else { return }
        guard let document: PDFDocument = self.document else { return }
        highlightService.addHighlight(selection: selection, color: color)
        persistDocument(document: document)
    }

    // MARK: - Remove highlight menu

    private func menuWithRemoveOption(annotation: PDFAnnotation, page: PDFPage) -> NSMenu {
        annotationPendingRemoval = annotation
        pagePendingRemoval = page
        let menu: NSMenu = NSMenu()
        menu.addItem(removeHighlightMenuItem)
        return menu
    }

    private var removeHighlightMenuItem: NSMenuItem {
        return makeMenuItem(title: "Remove Highlight", action: #selector(removeHighlight))
    }

    @objc private func removeHighlight() {
        guard let annotation: PDFAnnotation = annotationPendingRemoval else { return }
        guard let page: PDFPage = pagePendingRemoval else { return }
        guard let document: PDFDocument = self.document else { return }
        highlightService.removeHighlight(annotation: annotation, page: page)
        layoutDocumentView()
        persistDocument(document: document)
        annotationPendingRemoval = nil
        pagePendingRemoval = nil
    }

    private func makeMenuItem(title: String, action: Selector) -> NSMenuItem {
        let menuItem: NSMenuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.target = self
        return menuItem
    }

    private func persistDocument(document: PDFDocument) {
        guard let documentURL: URL = document.documentURL else { return }
        DispatchQueue.global(qos: .background).async {
            document.write(to: documentURL)
        }
    }
}
