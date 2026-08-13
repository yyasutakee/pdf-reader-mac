import AppKit

struct PDFThumbnailRepository {
    private let thumbnailsDirectoryName = "PDFThumbnails"

    private var thumbnailsDirectoryURL: URL? {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(thumbnailsDirectoryName)
    }

    // WHY: generated thumbnails need a stable cache URL that can be persisted with library metadata.
    func saveThumbnail(_ thumbnailImage: NSImage, for pdfFileIdentifier: UUID) -> URL? {
        guard let thumbnailsDirectory = thumbnailsDirectoryURL else { return nil }
        try? FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)

        let thumbnailFileURL = thumbnailsDirectory.appendingPathComponent("\(pdfFileIdentifier.uuidString).png")

        guard let tiffData = thumbnailImage.tiffRepresentation,
              let bitmapImageRepresentation = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImageRepresentation.representation(using: .png, properties: [:]) else { return nil }

        try? pngData.write(to: thumbnailFileURL)
        print("[PDFThumbnailRepository] saved thumbnail to: \(thumbnailFileURL)")
        return thumbnailFileURL
    }

    // WHY: removing a library entry also removes its now-unreferenced cached image.
    func deleteThumbnail(for pdfFileIdentifier: UUID) {
        guard let thumbnailsDirectory = thumbnailsDirectoryURL else { return }
        let thumbnailFileURL = thumbnailsDirectory.appendingPathComponent("\(pdfFileIdentifier.uuidString).png")
        try? FileManager.default.removeItem(at: thumbnailFileURL)
    }
}
