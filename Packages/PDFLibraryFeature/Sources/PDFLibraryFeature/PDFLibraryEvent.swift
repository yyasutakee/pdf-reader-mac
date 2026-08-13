import Foundation

public enum PDFLibraryEvent {
    case importButtonTapped
    case fileImporterDismissed
    case pdfFileSelected(URL)
    case libraryItemSelected(UUID?)
    case libraryItemRemovalRequested(UUID)
}
