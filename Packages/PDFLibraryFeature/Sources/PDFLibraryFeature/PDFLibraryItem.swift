import Foundation

public struct PDFLibraryItem: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let thumbnailURL: URL?
    public let currentPageNumber: Int
    public let totalPageCount: Int?
    public let lastReadDate: Date?

    public init(
        id: UUID,
        title: String,
        thumbnailURL: URL?,
        currentPageNumber: Int,
        totalPageCount: Int?,
        lastReadDate: Date?
    ) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.currentPageNumber = currentPageNumber
        self.totalPageCount = totalPageCount
        self.lastReadDate = lastReadDate
    }
}
