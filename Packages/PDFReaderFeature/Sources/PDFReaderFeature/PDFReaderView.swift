import SwiftUI

public struct PDFReaderView<Model: PDFReaderViewModel>: View {
    @ObservedObject private var model: Model
    @State private var isShowingRemovalConfirmation: Bool = false

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        readerContent
            .toolbar { readerToolbar }
            .alert("Remove all highlights?", isPresented: $isShowingRemovalConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove All", role: .destructive) { model.send(.allHighlightsRemovalRequested) }
            } message: {
                Text("This cannot be undone.")
            }
            .onChange(of: model.documentURL) { isShowingRemovalConfirmation = false }
    }

    @ViewBuilder
    private var readerContent: some View {
        if let documentURL: URL = model.documentURL {
            PDFDocumentView(
                documentURL: documentURL,
                initialPosition: model.initialPosition,
                isAllHighlightsRemovalPending: model.isAllHighlightsRemovalPending,
                onEvent: model.send
            )
            .overlay { nightModeOverlay }
        } else {
            noSelectionPlaceholder
        }
    }

    @ViewBuilder
    private var nightModeOverlay: some View {
        if model.isNightModeEnabled {
            Color.black.opacity(0.5).allowsHitTesting(false)
        }
    }

    @ToolbarContentBuilder
    private var readerToolbar: some ToolbarContent {
        if model.documentURL != nil {
            ToolbarItem(placement: .primaryAction) { nightModeButton }
            ToolbarItem(placement: .primaryAction) { removeAllHighlightsButton }
        }
    }

    private var nightModeButton: some View {
        Button(action: { model.send(.nightModeToggled) }) {
            Image(systemName: model.isNightModeEnabled ? "moon.fill" : "moon")
        }
        .help("Toggle night mode")
    }

    private var removeAllHighlightsButton: some View {
        Button(action: { isShowingRemovalConfirmation = true }) { Image(systemName: "eraser") }
            .help("Remove all highlights")
    }

    private var noSelectionPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Select a PDF to read")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
