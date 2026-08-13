import Foundation

struct ImportedPDFFile: Identifiable, Codable, Equatable {
    var id: UUID { identifier }
    let identifier: UUID
    let displayName: String
    let storedFileName: String
    let thumbnailFileURLAbsoluteString: String?
    let importedDate: Date
    var lastReadPageIndex: Int
    var lastReadScrollPosition: PDFScrollPosition?
    var lastReadDate: Date?
    var totalPageCount: Int?

    init(
        identifier: UUID,
        displayName: String,
        storedFileName: String,
        thumbnailFileURLAbsoluteString: String?,
        importedDate: Date,
        lastReadPageIndex: Int = 0,
        lastReadScrollPosition: PDFScrollPosition? = nil,
        lastReadDate: Date? = nil,
        totalPageCount: Int? = nil
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.storedFileName = storedFileName
        self.thumbnailFileURLAbsoluteString = thumbnailFileURLAbsoluteString
        self.importedDate = importedDate
        self.lastReadPageIndex = lastReadPageIndex
        self.lastReadScrollPosition = lastReadScrollPosition
        self.lastReadDate = lastReadDate
        self.totalPageCount = totalPageCount
    }
}
