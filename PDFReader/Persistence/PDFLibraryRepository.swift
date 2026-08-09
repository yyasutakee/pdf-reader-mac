import Foundation

class PDFLibraryRepository {
    private let userDefaultsStorageKey = "importedPDFFiles"

    func loadSavedPDFFiles() -> [ImportedPDFFile] {
        guard let encodedData = UserDefaults.standard.data(forKey: userDefaultsStorageKey),
              let importedPDFFiles = try? JSONDecoder().decode([ImportedPDFFile].self, from: encodedData) else {
            return []
        }
        return importedPDFFiles
    }

    func persistPDFFiles(_ importedPDFFiles: [ImportedPDFFile]) {
        guard let encodedData = try? JSONEncoder().encode(importedPDFFiles) else { return }
        UserDefaults.standard.set(encodedData, forKey: userDefaultsStorageKey)
    }
}
