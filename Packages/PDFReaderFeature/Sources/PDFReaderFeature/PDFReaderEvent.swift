public enum PDFReaderEvent {
    case nightModeToggled
    case allHighlightsRemovalRequested
    case allHighlightsRemovalHandled
    case currentPageChanged(Int)
    case currentPageBookmarkToggled
    case bookmarkSelected(Int)
    case bookmarkRemoved(Int)
    case bookmarkNavigationHandled
    case positionChanged(PDFReaderPosition)
}
