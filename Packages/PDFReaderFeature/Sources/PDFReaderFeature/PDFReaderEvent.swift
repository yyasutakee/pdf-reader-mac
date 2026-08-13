public enum PDFReaderEvent {
    case nightModeToggled
    case allHighlightsRemovalRequested
    case allHighlightsRemovalHandled
    case currentPageChanged(Int)
    case currentPageBookmarkToggled
    case bookmarkSelected(Int)
    case bookmarkRemoved(Int)
    case bookmarkCommentChanged(pageIndex: Int, comment: String?)
    case bookmarkNavigationHandled
    case positionChanged(PDFReaderPosition)
}
