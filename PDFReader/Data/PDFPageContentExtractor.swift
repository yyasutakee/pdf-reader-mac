import AppKit
import Foundation
import PDFKit
import Vision

struct PDFPageContentExtractor {
    private let minimumExtractedCharacterCount: Int = 20
    private let opticalRecognitionImageSize: NSSize = NSSize(width: 2_000, height: 2_000)

    // WHY: selected pages become page-addressable text without exposing PDFKit objects to domain state.
    func extractPageContents(documentURL: URL, pageRange: PDFPageRange) throws -> [PDFPageContent] {
        guard let document: PDFDocument = PDFDocument(url: documentURL) else { throw ExtractionError.documentUnavailable }
        guard isValidPageRange(pageRange, pageCount: document.pageCount) else { throw ExtractionError.invalidPageRange }
        return try pageRange.pageIndices.map { try extractPageContent(pageIndex: $0, document: document) }
    }

    // WHY: validation precedes PDFKit lookup so malformed requests never produce a partial result.
    private func isValidPageRange(_ pageRange: PDFPageRange, pageCount: Int) -> Bool {
        pageRange.lowerPageIndex >= 0 && pageRange.upperPageIndex < pageCount && pageRange.lowerPageIndex <= pageRange.upperPageIndex
    }

    // WHY: each page retains its source index so generated claims can navigate back to their evidence.
    private func extractPageContent(pageIndex: Int, document: PDFDocument) throws -> PDFPageContent {
        guard let page: PDFPage = document.page(at: pageIndex) else { throw ExtractionError.documentUnavailable }
        let embeddedText: String = normalizeText(page.string ?? "")
        let text: String = embeddedText.count >= minimumExtractedCharacterCount ? embeddedText : try recognizePageText(page)
        return PDFPageContent(pageIndex: pageIndex, text: text)
    }

    // WHY: scanned pages need an on-device fallback when the PDF contains no useful text layer.
    private func recognizePageText(_ page: PDFPage) throws -> String {
        let pageImage: NSImage = page.thumbnail(of: opticalRecognitionImageSize, for: .cropBox)
        guard let image: CGImage = pageImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return "" }
        let request: VNRecognizeTextRequest = makeTextRecognitionRequest()
        try VNImageRequestHandler(cgImage: image).perform([request])
        return normalizeText(makeRecognizedText(request.results ?? []))
    }

    // WHY: accurate recognition is preferred because this text becomes factual source material for answers.
    private func makeTextRecognitionRequest() -> VNRecognizeTextRequest {
        let request: VNRecognizeTextRequest = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        return request
    }

    // WHY: Vision observations are flattened in reading order into the same representation as PDFKit text.
    private func makeRecognizedText(_ observations: [VNRecognizedTextObservation]) -> String {
        observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }

    // WHY: one whitespace policy prevents empty-looking pages and noisy spacing from reaching the model.
    private func normalizeText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum ExtractionError: Error {
        case documentUnavailable
        case invalidPageRange
    }
}
