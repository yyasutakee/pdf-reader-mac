import SwiftUI
internal import UniformTypeIdentifiers

struct PDFLibraryView: View {
    @ObservedObject var pdfLibraryStore: PDFLibraryStore
    @State private var isShowingClearHighlightsConfirmation: Bool = false
    @State private var clearAllHighlightsRequested: Bool = false

    var body: some View {
        NavigationSplitView {
            sidebarView
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
            detailView
        }
        .fileImporter(
            isPresented: Binding(
                get: { pdfLibraryStore.state.isShowingFilePicker },
                set: { _ in pdfLibraryStore.dismissFilePicker() }
            ),
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { importResult in
            switch importResult {
            case .success(let selectedFileURLs):
                guard let selectedFileURL = selectedFileURLs.first else { return }
                pdfLibraryStore.importPDFFile(from: selectedFileURL)
            case .failure:
                pdfLibraryStore.dismissFilePicker()
            }
        }
        .alert("Remove all highlights?", isPresented: $isShowingClearHighlightsConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove All", role: .destructive) { clearAllHighlightsRequested = true }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var clearAllHighlightsButton: some View {
        Button(action: { isShowingClearHighlightsConfirmation = true }) {
            Image(systemName: "eraser")
        }
        .help("Remove all highlights")
    }

    private var sidebarView: some View {
        Group {
            if pdfLibraryStore.state.importedPDFFiles.isEmpty {
                emptyLibraryPlaceholderView
            } else {
                List(pdfLibraryStore.state.importedPDFFiles,
                     selection: Binding(
                        get: { pdfLibraryStore.state.selectedPDFFile?.identifier },
                        set: { selectedIdentifier in
                            if let identifier = selectedIdentifier,
                               let file = pdfLibraryStore.state.importedPDFFiles.first(where: { $0.identifier == identifier }) {
                                pdfLibraryStore.selectPDFFile(file)
                            } else {
                                pdfLibraryStore.deselectPDFFile()
                            }
                        }
                     )
                ) { importedPDFFile in
                    PDFLibraryItemView(
                        importedPDFFile: importedPDFFile,
                        isSelected: pdfLibraryStore.state.selectedPDFFile?.identifier == importedPDFFile.identifier,
                        onDeleteRequested: { pdfLibraryStore.removeImportedPDFFile(importedPDFFile) }
                    )
                    .tag(importedPDFFile.identifier)
                }
            }
        }
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: pdfLibraryStore.presentFilePicker) {
                    Label("Import PDF", systemImage: "plus")
                }
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let selectedFileURL = pdfLibraryStore.state.selectedPDFFileURL,
           let selectedPDFFile = pdfLibraryStore.state.selectedPDFFile {
            PDFReaderView(
                pdfFileURL: selectedFileURL,
                initialScrollPosition: selectedPDFFile.lastReadScrollPosition,
                clearAllHighlightsRequested: $clearAllHighlightsRequested,
                onScrollPositionChanged: { scrollPosition in
                    pdfLibraryStore.saveScrollPosition(scrollPosition: scrollPosition, for: selectedPDFFile)
                }
            )
            .overlay(
                Group {
                    if pdfLibraryStore.state.isNightModeEnabled {
                        Color.black.opacity(0.5)
                    }
                }
                .allowsHitTesting(false)
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: pdfLibraryStore.toggleNightMode) {
                        Image(systemName: pdfLibraryStore.state.isNightModeEnabled ? "moon.fill" : "moon")
                    }
                    .help("Toggle night mode")
                }
                ToolbarItem(placement: .primaryAction) {
                    clearAllHighlightsButton
                }
            }
            .onChange(of: pdfLibraryStore.state.selectedPDFFile?.identifier) {
                isShowingClearHighlightsConfirmation = false
                clearAllHighlightsRequested = false
            }
        } else {
            noSelectionPlaceholderView
        }
    }

    private var emptyLibraryPlaceholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No PDFs in your library")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Click + to import a PDF.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noSelectionPlaceholderView: some View {
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
