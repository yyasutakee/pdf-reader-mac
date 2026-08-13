import Foundation

public enum PDFLibraryEvent {
    case importButtonTapped
    case fileImporterDismissed
    case pdfFileSelected(URL)
    case libraryItemSelected(UUID?)
    case libraryItemRevealRequested(UUID)
    case libraryItemRemovalRequested(UUID)
}
