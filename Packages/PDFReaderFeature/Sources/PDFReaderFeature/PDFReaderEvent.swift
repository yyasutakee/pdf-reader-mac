public enum PDFReaderEvent {
    case nightModeToggled
    case allHighlightsRemovalRequested
    case allHighlightsRemovalHandled
    case positionChanged(PDFReaderPosition)
}
