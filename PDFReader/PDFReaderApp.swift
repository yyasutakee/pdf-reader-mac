import SwiftUI

@main
struct PDFReaderApp: App {
    @AppStorage("appearanceTheme") private var appearanceTheme: AppearanceTheme = .system

    private let pdfLibraryStore = PDFLibraryStore(
        pdfLibraryRepository: PDFLibraryRepository(),
        pdfFileStorageService: PDFFileStorageService(),
        pdfThumbnailService: PDFThumbnailService(),
        pdfThumbnailRepository: PDFThumbnailRepository()
    )

    var body: some Scene {
        WindowGroup {
            PDFLibraryView(pdfLibraryStore: pdfLibraryStore)
                .preferredColorScheme(appearanceTheme.colorScheme)
        }

        Settings {
            SettingsView()
        }
    }
}
