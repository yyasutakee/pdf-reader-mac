import Foundation

struct PDFFileStorageService {
    private let pdfSubdirectoryName = "PDFs"

    private var storageFolderURL: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(pdfSubdirectoryName)
    }

    // WHY: imported security-scoped files must be copied into app-owned storage for later access.
    func copyPDFFileIntoStorage(from sourceFileURL: URL) -> String? {
        guard let folderURL = storageFolderURL else {
            print("[PDFFileStorageService] could not resolve storage folder")
            return nil
        }

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let storedFileName = UUID().uuidString + ".pdf"
            let destinationFileURL = folderURL.appendingPathComponent(storedFileName)
            try FileManager.default.copyItem(at: sourceFileURL, to: destinationFileURL)
            print("[PDFFileStorageService] copied to: \(destinationFileURL)")
            return storedFileName
        } catch {
            print("[PDFFileStorageService] copy failed: \(error)")
            return nil
        }
    }

    // WHY: persisted metadata stores a portable filename rather than an environment-specific absolute URL.
    func resolveStoredFileURL(storedFileName: String) -> URL? {
        guard let fileURL: URL = storageFolderURL?.appendingPathComponent(storedFileName) else { return nil }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return fileURL
    }

    // WHY: removing library metadata must also release the app-owned PDF file.
    func deleteStoredFile(storedFileName: String) {
        guard let fileURL = resolveStoredFileURL(storedFileName: storedFileName) else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }
}
