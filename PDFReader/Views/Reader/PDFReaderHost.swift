import PDFReaderFeature
import SwiftUI

struct PDFReaderHost: View {
    @StateObject private var viewStore: PDFReaderViewStore

    init(appStore: AppStore) {
        _viewStore = StateObject(wrappedValue: PDFReaderViewStore(appStore: appStore))
    }

    var body: some View {
        PDFReaderView(model: viewStore)
    }
}
