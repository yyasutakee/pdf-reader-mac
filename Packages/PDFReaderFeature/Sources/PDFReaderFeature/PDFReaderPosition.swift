import Foundation

public struct PDFReaderPosition: Equatable, Sendable {
    public let pageIndex: Int
    public let pagePointX: Double
    public let pagePointY: Double
    public let zoomScale: Double

    public init(pageIndex: Int, pagePointX: Double, pagePointY: Double, zoomScale: Double) {
        self.pageIndex = pageIndex
        self.pagePointX = pagePointX
        self.pagePointY = pagePointY
        self.zoomScale = zoomScale
    }
}
