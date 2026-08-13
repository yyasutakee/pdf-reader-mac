struct PDFPageBookmark: Codable, Equatable {
    let pageIndex: Int
    var comment: String?
}
