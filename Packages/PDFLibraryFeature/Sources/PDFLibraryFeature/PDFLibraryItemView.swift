import AppKit
import SwiftUI

struct PDFLibraryItemView: View {
    let item: PDFLibraryItem
    let isSelected: Bool
    let onDeleteRequested: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            coverThumbnail
            itemInformation
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu { removeButton }
    }

    private var coverThumbnail: some View {
        thumbnailContent
            .frame(width: 36, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let image: NSImage = loadThumbnailImage() {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
        } else {
            fallbackThumbnail
        }
    }

    private var fallbackThumbnail: some View {
        Image(systemName: "doc.text.fill")
            .font(.system(size: 20))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
    }

    private var itemInformation: some View {
        VStack(alignment: .leading, spacing: 4) {
            title
            readingProgress
            lastReadDate
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: some View {
        Text(item.title)
            .font(.system(size: 12))
            .lineLimit(2)
            .foregroundStyle(isSelected ? .white : .primary)
    }

    @ViewBuilder
    private var readingProgress: some View {
        if let totalPageCount: Int = item.totalPageCount, totalPageCount > 0 {
            readingProgressContent(totalPageCount: totalPageCount)
        }
    }

    private func readingProgressContent(totalPageCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Page \(item.currentPageNumber) of \(totalPageCount)")
                .font(.system(size: 10))
                .foregroundStyle(secondaryForegroundStyle)
            ProgressView(value: calculateProgressFraction(totalPageCount: totalPageCount))
                .progressViewStyle(.linear)
                .tint(isSelected ? .white : .accentColor)
        }
    }

    @ViewBuilder
    private var lastReadDate: some View {
        if let date: Date = item.lastReadDate {
            Text("Read \(formatLastReadDate(date))")
                .font(.system(size: 10))
                .foregroundStyle(secondaryForegroundStyle)
        }
    }

    private var secondaryForegroundStyle: Color {
        isSelected ? .white.opacity(0.7) : .secondary
    }

    private var removeButton: some View {
        Button(role: .destructive, action: onDeleteRequested) {
            Label("Remove from Library", systemImage: "trash")
        }
    }

    // WHY: thumbnail loading belongs to this display-only item because the package receives only a file URL.
    private func loadThumbnailImage() -> NSImage? {
        guard let thumbnailURL: URL = item.thumbnailURL else { return nil }
        return NSImage(contentsOf: thumbnailURL)
    }

    // WHY: progress is derived here because it is presentation formatting rather than domain state.
    private func calculateProgressFraction(totalPageCount: Int) -> Double {
        guard totalPageCount > 1 else { return 1 }
        return Double(item.currentPageNumber - 1) / Double(totalPageCount - 1)
    }

    // WHY: relative wording is a display decision owned by the feature rather than the domain.
    private func formatLastReadDate(_ date: Date) -> String {
        guard !Calendar.current.isDateInToday(date) else { return "today" }
        return date.formatted(Date.FormatStyle().month(.abbreviated).day())
    }
}
