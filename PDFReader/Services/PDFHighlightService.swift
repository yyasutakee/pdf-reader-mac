import PDFKit
import AppKit

struct PDFHighlightService {
    func addHighlight(selection: PDFSelection, color: NSColor) {
        selection.pages.forEach { addHighlightAnnotation(page: $0, selection: selection, color: color) }
    }

    func removeHighlight(annotation: PDFAnnotation, page: PDFPage) {
        page.removeAnnotation(annotation)
    }

    func removeAllHighlights(document: PDFDocument) {
        (0..<document.pageCount).forEach { removeAllHighlights(pageIndex: $0, document: document) }
    }

    static func isHighlightAnnotation(annotation: PDFAnnotation) -> Bool {
        return annotation.type == "Highlight" || annotation.type == "/Highlight"
    }

    private func addHighlightAnnotation(page: PDFPage, selection: PDFSelection, color: NSColor) {
        page.addAnnotation(makeHighlightAnnotation(bounds: selection.bounds(for: page), color: color))
    }

    private func makeHighlightAnnotation(bounds: NSRect, color: NSColor) -> PDFAnnotation {
        let annotation: PDFAnnotation = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
        annotation.color = color.withAlphaComponent(0.6)
        return annotation
    }

    private func removeAllHighlights(pageIndex: Int, document: PDFDocument) {
        guard let page: PDFPage = document.page(at: pageIndex) else { return }
        highlightAnnotations(page: page).forEach { page.removeAnnotation($0) }
    }

    private func highlightAnnotations(page: PDFPage) -> [PDFAnnotation] {
        return page.annotations.filter { PDFHighlightService.isHighlightAnnotation(annotation: $0) }
    }
}
