import Foundation

struct PDFScrollPosition: Codable, Equatable {
    let pageIndex: Int
    let pagePointX: Double
    let pagePointY: Double
    let zoomScale: Double
}
