import Combine
import Foundation

@MainActor
public protocol PDFLibraryViewModel: ObservableObject {
    var items: [PDFLibraryItem] { get }
    var selectedItemIdentifier: UUID? { get }
    var isFileImporterPresented: Bool { get }

    // WHY: one event door keeps the package independent from the app's state and persistence APIs.
    func send(_ event: PDFLibraryEvent)
}
