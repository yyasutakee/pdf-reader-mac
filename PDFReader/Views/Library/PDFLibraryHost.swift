import PDFLibraryFeature
import SwiftUI

struct PDFLibraryHost: View {
    @StateObject private var viewStore: PDFLibraryViewStore
    private let appStore: AppStore

    init(appStore: AppStore) {
        self.appStore = appStore
        _viewStore = StateObject(wrappedValue: PDFLibraryViewStore(appStore: appStore))
    }

    var body: some View {
        PDFLibraryView(model: viewStore) { PDFReaderHost(appStore: appStore) }
    }
}
