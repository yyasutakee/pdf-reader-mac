import SwiftUI

struct PDFLibraryItemView: View {
    let importedPDFFile: ImportedPDFFile
    let isSelected: Bool
    let onDeleteRequested: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            pdfCoverThumbnailView
                .frame(width: 36, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            VStack(alignment: .leading, spacing: 4) {
                Text(importedPDFFile.displayName)
                    .font(.system(size: 12))
                    .lineLimit(2)
                    .foregroundStyle(isSelected ? .white : .primary)

                readingProgressView
                lastReadDateView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive, action: onDeleteRequested) {
                Label("Remove from Library", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var readingProgressView: some View {
        if let totalPageCount = importedPDFFile.totalPageCount, totalPageCount > 0 {
            let currentPage = importedPDFFile.lastReadPageIndex + 1
            let progressFraction = Double(importedPDFFile.lastReadPageIndex) / Double(totalPageCount - 1)

            VStack(alignment: .leading, spacing: 2) {
                Text("Page \(currentPage) of \(totalPageCount)")
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)

                ProgressView(value: progressFraction)
                    .progressViewStyle(.linear)
                    .tint(isSelected ? .white : .accentColor)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var lastReadDateView: some View {
        if let date: Date = importedPDFFile.lastReadDate {
            Text("Read \(lastReadDateLabel(date: date))")
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
        }
    }

    private func lastReadDateLabel(date: Date) -> String {
        guard !Calendar.current.isDateInToday(date) else { return "today" }
        return date.formatted(Date.FormatStyle().month(.abbreviated).day())
    }

    @ViewBuilder
    private var pdfCoverThumbnailView: some View {
        if let thumbnailURLString = importedPDFFile.thumbnailFileURLAbsoluteString,
           let thumbnailURL = URL(string: thumbnailURLString),
           let thumbnailNSImage = NSImage(contentsOf: thumbnailURL) {
            Image(nsImage: thumbnailNSImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 20))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
        }
    }
}
