public struct PDFBookmarkItem: Identifiable, Hashable, Sendable {
    public let pageIndex: Int
    public let comment: String?
    public var id: Int { pageIndex }
    public var pageNumber: Int { pageIndex + 1 }

    public init(pageIndex: Int, comment: String?) {
        self.pageIndex = pageIndex
        self.comment = comment
    }
}
