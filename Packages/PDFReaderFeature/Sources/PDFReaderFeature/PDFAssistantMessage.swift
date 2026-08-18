import Foundation

public struct PDFAssistantMessage: Identifiable, Equatable {
    public enum Author: Equatable {
        case person
        case assistant
    }

    public let id: UUID
    public let author: Author
    public let text: String
    public let pageRangeDescription: String
    public let referencePageNumbers: [Int]

    public init(id: UUID, author: Author, text: String, pageRangeDescription: String, referencePageNumbers: [Int]) {
        self.id = id
        self.author = author
        self.text = text
        self.pageRangeDescription = pageRangeDescription
        self.referencePageNumbers = referencePageNumbers
    }
}
