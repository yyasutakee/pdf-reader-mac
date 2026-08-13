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
    var bookmarks: [PDFPageBookmark]

    init(
        identifier: UUID,
        displayName: String,
        storedFileName: String,
        thumbnailFileURLAbsoluteString: String?,
        importedDate: Date,
        lastReadPageIndex: Int = 0,
        lastReadScrollPosition: PDFScrollPosition? = nil,
        lastReadDate: Date? = nil,
        totalPageCount: Int? = nil,
        bookmarks: [PDFPageBookmark] = []
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
        self.bookmarks = bookmarks
    }

    init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(UUID.self, forKey: .identifier)
        displayName = try container.decode(String.self, forKey: .displayName)
        storedFileName = try container.decode(String.self, forKey: .storedFileName)
        thumbnailFileURLAbsoluteString = try container.decodeIfPresent(String.self, forKey: .thumbnailFileURLAbsoluteString)
        importedDate = try container.decode(Date.self, forKey: .importedDate)
        lastReadPageIndex = try container.decodeIfPresent(Int.self, forKey: .lastReadPageIndex) ?? 0
        lastReadScrollPosition = try container.decodeIfPresent(PDFScrollPosition.self, forKey: .lastReadScrollPosition)
        lastReadDate = try container.decodeIfPresent(Date.self, forKey: .lastReadDate)
        totalPageCount = try container.decodeIfPresent(Int.self, forKey: .totalPageCount)
        bookmarks = try Self.decodeBookmarks(from: decoder, container: container)
    }

    private enum CodingKeys: String, CodingKey {
        case identifier
        case displayName
        case storedFileName
        case thumbnailFileURLAbsoluteString
        case importedDate
        case lastReadPageIndex
        case lastReadScrollPosition
        case lastReadDate
        case totalPageCount
        case bookmarks
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case bookmarkedPageIndices
    }

    private static func decodeBookmarks(
        from decoder: any Decoder,
        container: KeyedDecodingContainer<CodingKeys>
    ) throws -> [PDFPageBookmark] {
        if let bookmarks: [PDFPageBookmark] = try container.decodeIfPresent([PDFPageBookmark].self, forKey: .bookmarks) { return bookmarks }
        let legacyContainer: KeyedDecodingContainer<LegacyCodingKeys> = try decoder.container(keyedBy: LegacyCodingKeys.self)
        let pageIndices: [Int] = try legacyContainer.decodeIfPresent([Int].self, forKey: .bookmarkedPageIndices) ?? []
        return pageIndices.map { PDFPageBookmark(pageIndex: $0, comment: nil) }
    }
}
