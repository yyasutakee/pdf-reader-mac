import Foundation

struct PDFLibraryRepository {
    private let userDefaultsStorageKey = "importedPDFFiles"

    // WHY: persisted library metadata initializes the app's single state tree at launch.
    func loadSavedPDFFiles() -> [ImportedPDFFile] {
        guard let encodedData = UserDefaults.standard.data(forKey: userDefaultsStorageKey),
              let importedPDFFiles = try? JSONDecoder().decode([ImportedPDFFile].self, from: encodedData) else {
            return []
        }
        return importedPDFFiles
    }

    // WHY: the repository is the sole encoder for library metadata stored in UserDefaults.
    func persistPDFFiles(_ importedPDFFiles: [ImportedPDFFile]) {
        guard let encodedData = try? JSONEncoder().encode(importedPDFFiles) else { return }
        UserDefaults.standard.set(encodedData, forKey: userDefaultsStorageKey)
    }
}
