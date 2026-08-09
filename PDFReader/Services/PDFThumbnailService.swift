import PDFKit
import AppKit

class PDFThumbnailService {
    func generateFirstPageThumbnail(for pdfFileURL: URL, thumbnailSize: CGSize) -> NSImage? {
        guard let pdfDocument = PDFDocument(url: pdfFileURL),
              let firstPage = pdfDocument.page(at: 0) else {
            print("[PDFThumbnailService] failed to open: \(pdfFileURL)")
            return nil
        }
        return firstPage.thumbnail(of: thumbnailSize, for: .mediaBox)
    }
}
