import SwiftUI

public struct PDFReaderView<Model: PDFReaderViewModel>: View {
    @ObservedObject private var model: Model
    @State private var isShowingRemovalConfirmation: Bool = false
    @State private var isShowingBookmarksInspector: Bool = false

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        readerContent
            .toolbar { readerToolbar }
            .inspector(isPresented: $isShowingBookmarksInspector) { bookmarksInspector }
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
                bookmarkNavigationPageIndex: model.bookmarkNavigationPageIndex,
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
            ToolbarItem(placement: .primaryAction) { currentPageBookmarkButton }
            ToolbarItem(placement: .primaryAction) { bookmarksInspectorButton }
            ToolbarItem(placement: .primaryAction) { nightModeButton }
            ToolbarItem(placement: .primaryAction) { removeAllHighlightsButton }
        }
    }

    private var currentPageBookmarkButton: some View {
        Button(action: { model.send(.currentPageBookmarkToggled) }) {
            Image(systemName: model.isCurrentPageBookmarked ? "bookmark.fill" : "bookmark")
        }
        .keyboardShortcut("d", modifiers: .command)
        .help(currentPageBookmarkHelp)
        .disabled(model.currentPageIndex == nil)
    }

    private var currentPageBookmarkHelp: String {
        guard let pageIndex: Int = model.currentPageIndex else { return "Bookmark Current Page" }
        let action: String = model.isCurrentPageBookmarked ? "Remove Bookmark from" : "Bookmark"
        return "\(action) Page \(pageIndex + 1)"
    }

    private var bookmarksInspectorButton: some View {
        Button(action: { isShowingBookmarksInspector.toggle() }) {
            Label("Bookmarks", systemImage: "sidebar.right")
        }
        .help(isShowingBookmarksInspector ? "Hide Bookmarks" : "Show Bookmarks")
    }

    private var bookmarksInspector: some View {
        Group {
            if model.bookmarks.isEmpty { emptyBookmarksPlaceholder } else { bookmarksList }
        }
        .navigationTitle("Bookmarks")
        .inspectorColumnWidth(min: 180, ideal: 220, max: 300)
    }

    private var bookmarksList: some View {
        List(model.bookmarks) { bookmark in
            bookmarkRow(bookmark)
        }
    }

    private func bookmarkRow(_ bookmark: PDFBookmarkItem) -> some View {
        BookmarkRow(
            bookmark: bookmark,
            onSelected: { model.send(.bookmarkSelected(bookmark.pageIndex)) },
            onRemoved: { model.send(.bookmarkRemoved(bookmark.pageIndex)) },
            onCommentChanged: { model.send(.bookmarkCommentChanged(pageIndex: bookmark.pageIndex, comment: $0)) }
        )
    }

    private var emptyBookmarksPlaceholder: some View {
        ContentUnavailableView(
            "No Bookmarks",
            systemImage: "bookmark",
            description: Text("Bookmark a page to find it here.")
        )
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

    private struct BookmarkRow: View {
        let bookmark: PDFBookmarkItem
        let onSelected: () -> Void
        let onRemoved: () -> Void
        let onCommentChanged: (String?) -> Void

        @State private var commentText: String
        @FocusState private var isCommentFocused: Bool

        init(
            bookmark: PDFBookmarkItem,
            onSelected: @escaping () -> Void,
            onRemoved: @escaping () -> Void,
            onCommentChanged: @escaping (String?) -> Void
        ) {
            self.bookmark = bookmark
            self.onSelected = onSelected
            self.onRemoved = onRemoved
            self.onCommentChanged = onCommentChanged
            _commentText = State(initialValue: bookmark.comment ?? "")
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                bookmarkHeader
                commentField
            }
            .contextMenu { removeBookmarkMenuButton }
            .onChange(of: isCommentFocused) { _, isFocused in if !isFocused { commitComment() } }
            .onChange(of: bookmark.comment) { _, comment in synchronizeComment(comment) }
        }

        private var bookmarkHeader: some View {
            HStack {
                Button(action: onSelected) {
                    Label("Page \(bookmark.pageNumber)", systemImage: "bookmark.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                Spacer()
                removeBookmarkButton
            }
            .contentShape(Rectangle())
        }

        private var commentField: some View {
            TextField("Add a comment", text: $commentText)
                .textFieldStyle(.roundedBorder)
                .focused($isCommentFocused)
                .onSubmit(commitComment)
        }

        private var removeBookmarkButton: some View {
            Button(action: onRemoved) {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Remove Bookmark")
        }

        private var removeBookmarkMenuButton: some View {
            Button(role: .destructive, action: onRemoved) {
                Label("Remove Bookmark", systemImage: "trash")
            }
        }

        private func commitComment() {
            onCommentChanged(commentText)
        }

        private func synchronizeComment(_ comment: String?) {
            guard !isCommentFocused else { return }
            commentText = comment ?? ""
        }
    }
}
