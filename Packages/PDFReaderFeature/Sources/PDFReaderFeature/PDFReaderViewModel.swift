import Combine
import Foundation

@MainActor
public protocol PDFReaderViewModel: ObservableObject {
    var documentURL: URL? { get }
    var initialPosition: PDFReaderPosition? { get }
    var isNightModeEnabled: Bool { get }
    var isAllHighlightsRemovalPending: Bool { get }
    var currentPageIndex: Int? { get }
    var bookmarks: [PDFBookmarkItem] { get }
    var isCurrentPageBookmarked: Bool { get }
    var bookmarkNavigationPageIndex: Int? { get }

    // WHY: one event door prevents PDF rendering controls from learning about app state or persistence.
    func send(_ event: PDFReaderEvent)
}
