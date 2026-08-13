import AppKit
import PDFKit

final class HighlightablePDFView: PDFView {
    private var annotationPendingRemoval: PDFAnnotation?
    private var pagePendingRemoval: PDFPage?
    private var pendingPosition: PDFReaderPosition?
    var onLiveScroll: (() -> Void)?

    // WHY: a pending destination can only be applied after PDFKit has laid out its document view.
    override func layout() {
        super.layout()
        navigateToPendingPositionIfNeeded()
    }

    // WHY: the clip view exists only after attachment to a window, so scrolling observation starts here.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        registerClipViewBoundsObserver()
    }

    // WHY: context-menu behavior is selected from either an existing annotation or active text selection.
    override func menu(for event: NSEvent) -> NSMenu? {
        if let annotationContext: AnnotationContext = findHighlightAnnotation(windowPoint: event.locationInWindow) {
            return makeRemovalMenu(annotationContext: annotationContext)
        }
        guard hasActiveTextSelection else { return super.menu(for: event) }
        return makeHighlightMenu(baseMenu: super.menu(for: event))
    }

    // WHY: restoration may arrive before layout, so the value is retained until PDFKit can navigate.
    func restorePendingPosition(_ position: PDFReaderPosition?) {
        pendingPosition = position
        navigateToPendingPositionIfNeeded()
    }

    // WHY: the reader command removes every highlight from the currently loaded document in one place.
    func removeAllHighlights() {
        guard let document: PDFDocument = document else { return }
        removeHighlights(from: document)
        layoutDocumentView()
        persistDocument(document)
    }

    // WHY: navigation is retried after layout until a valid destination can be built.
    private func navigateToPendingPositionIfNeeded() {
        guard let position: PDFReaderPosition = pendingPosition else { return }
        guard let destination: PDFDestination = makeDestination(position: position) else { return }
        pendingPosition = nil
        go(to: destination)
    }

    // WHY: a display position must be validated against the currently loaded PDF before navigation.
    private func makeDestination(position: PDFReaderPosition) -> PDFDestination? {
        guard let document: PDFDocument = document else { return nil }
        guard position.pageIndex < document.pageCount else { return nil }
        guard let page: PDFPage = document.page(at: position.pageIndex) else { return nil }
        return PDFDestination(page: page, at: CGPoint(x: position.pagePointX, y: position.pagePointY))
    }

    // WHY: live scrolling is exposed by the enclosing clip view rather than PDFView itself.
    private func registerClipViewBoundsObserver() {
        guard let clipView: NSClipView = documentView?.enclosingScrollView?.contentView else { return }
        clipView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClipViewBoundsChanged),
            name: NSView.boundsDidChangeNotification,
            object: clipView
        )
    }

    // WHY: the callback lets the representable debounce persistence without coupling this view to a model.
    @objc private func handleClipViewBoundsChanged() {
        onLiveScroll?()
    }

    private var hasActiveTextSelection: Bool {
        currentSelection?.string?.isEmpty == false
    }

    private var highlightSubmenu: NSMenu {
        let menu: NSMenu = NSMenu(title: "Highlight")
        addHighlightChoices(to: menu)
        return menu
    }

    private var removalMenuItem: NSMenuItem {
        makeMenuItem(title: "Remove Highlight", action: #selector(removeSelectedHighlight))
    }

    // WHY: all supported colors are declared together so the menu cannot drift from its selectors.
    private func addHighlightChoices(to menu: NSMenu) {
        menu.addItem(makeMenuItem(title: "Blue", action: #selector(applyBlueHighlight)))
        menu.addItem(makeMenuItem(title: "Purple", action: #selector(applyPurpleHighlight)))
        menu.addItem(makeMenuItem(title: "Pink", action: #selector(applyPinkHighlight)))
        menu.addItem(makeMenuItem(title: "Orange", action: #selector(applyOrangeHighlight)))
        menu.addItem(makeMenuItem(title: "Yellow", action: #selector(applyYellowHighlight)))
        menu.addItem(makeMenuItem(title: "Green", action: #selector(applyGreenHighlight)))
    }

    // WHY: the contextual location is translated into a page annotation before menu construction.
    private func findHighlightAnnotation(windowPoint: NSPoint) -> AnnotationContext? {
        let localPoint: NSPoint = convert(windowPoint, from: nil)
        guard let page: PDFPage = page(for: localPoint, nearest: false) else { return nil }
        let pagePoint: NSPoint = convert(localPoint, to: page)
        guard let annotation: PDFAnnotation = findHighlightAnnotation(page: page, pagePoint: pagePoint) else { return nil }
        return AnnotationContext(annotation: annotation, page: page)
    }

    // WHY: only highlight annotations under the pointer qualify for the destructive contextual action.
    private func findHighlightAnnotation(page: PDFPage, pagePoint: NSPoint) -> PDFAnnotation? {
        page.annotations.first { isHighlightAnnotation($0) && $0.bounds.contains(pagePoint) }
    }

    // WHY: PDFKit can expose annotation type names with or without a leading slash.
    private func isHighlightAnnotation(_ annotation: PDFAnnotation) -> Bool {
        annotation.type == "Highlight" || annotation.type == "/Highlight"
    }

    // WHY: the existing PDFKit menu is augmented instead of discarded so standard actions remain available.
    private func makeHighlightMenu(baseMenu: NSMenu?) -> NSMenu {
        let menu: NSMenu = baseMenu ?? NSMenu()
        let item: NSMenuItem = NSMenuItem(title: "Highlight", action: nil, keyEquivalent: "")
        item.submenu = highlightSubmenu
        menu.insertItem(item, at: 0)
        menu.insertItem(.separator(), at: 1)
        return menu
    }

    // WHY: the chosen annotation context is retained until AppKit invokes the menu action.
    private func makeRemovalMenu(annotationContext: AnnotationContext) -> NSMenu {
        annotationPendingRemoval = annotationContext.annotation
        pagePendingRemoval = annotationContext.page
        let menu: NSMenu = NSMenu()
        menu.addItem(removalMenuItem)
        return menu
    }

    // WHY: AppKit selectors require a concrete method for each menu choice.
    @objc private func applyBlueHighlight() { applyHighlight(color: .systemBlue) }
    // WHY: AppKit selectors require a concrete method for each menu choice.
    @objc private func applyPurpleHighlight() { applyHighlight(color: .systemPurple) }
    // WHY: AppKit selectors require a concrete method for each menu choice.
    @objc private func applyPinkHighlight() { applyHighlight(color: .systemPink) }
    // WHY: AppKit selectors require a concrete method for each menu choice.
    @objc private func applyOrangeHighlight() { applyHighlight(color: .systemOrange) }
    // WHY: AppKit selectors require a concrete method for each menu choice.
    @objc private func applyYellowHighlight() { applyHighlight(color: .systemYellow) }
    // WHY: AppKit selectors require a concrete method for each menu choice.
    @objc private func applyGreenHighlight() { applyHighlight(color: .systemGreen) }

    // WHY: one implementation applies every menu color with identical persistence behavior.
    private func applyHighlight(color: NSColor) {
        guard let selection: PDFSelection = currentSelection else { return }
        guard let document: PDFDocument = document else { return }
        selection.pages.forEach { addHighlight(page: $0, selection: selection, color: color) }
        persistDocument(document)
    }

    // WHY: annotation construction is isolated so its opacity and PDF subtype have one definition.
    private func addHighlight(page: PDFPage, selection: PDFSelection, color: NSColor) {
        let annotation: PDFAnnotation = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
        annotation.color = color.withAlphaComponent(0.6)
        page.addAnnotation(annotation)
    }

    // WHY: the contextual action removes exactly the annotation chosen when the menu opened.
    @objc private func removeSelectedHighlight() {
        guard let annotation: PDFAnnotation = annotationPendingRemoval else { return }
        guard let page: PDFPage = pagePendingRemoval else { return }
        guard let document: PDFDocument = document else { return }
        page.removeAnnotation(annotation)
        clearPendingRemoval()
        layoutDocumentView()
        persistDocument(document)
    }

    // WHY: one reset prevents a later menu action from using a stale PDFKit object.
    private func clearPendingRemoval() {
        annotationPendingRemoval = nil
        pagePendingRemoval = nil
    }

    // WHY: document-wide removal delegates each page to the same annotation predicate.
    private func removeHighlights(from document: PDFDocument) {
        (0..<document.pageCount).forEach { removeHighlights(pageIndex: $0, document: document) }
    }

    // WHY: page lookup and mutation are scoped together because missing pages are safely ignored.
    private func removeHighlights(pageIndex: Int, document: PDFDocument) {
        guard let page: PDFPage = document.page(at: pageIndex) else { return }
        page.annotations.filter(isHighlightAnnotation).forEach(page.removeAnnotation)
    }

    // WHY: every contextual item needs this view as its AppKit action target.
    private func makeMenuItem(title: String, action: Selector) -> NSMenuItem {
        let item: NSMenuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    // WHY: annotation changes must be written back without blocking the main event loop.
    private func persistDocument(_ document: PDFDocument) {
        guard let documentURL: URL = document.documentURL else { return }
        DispatchQueue.global(qos: .background).async { document.write(to: documentURL) }
    }

    private struct AnnotationContext {
        let annotation: PDFAnnotation
        let page: PDFPage
    }
}
