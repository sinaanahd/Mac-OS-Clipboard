import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ClipboardHistoryStore
    var onRestore: () -> Void = {}
    @State private var query = ""

    private var filteredEntries: [ClipboardEntry] {
        query.isEmpty ? store.entries : store.entries.filter {
            $0.preview.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: VisualConfiguration.searchFieldSpacing) {
            TextField("Search clipboard history", text: $query)
                .textFieldStyle(.roundedBorder)
            if filteredEntries.isEmpty {
                ContentUnavailableView(
                    query.isEmpty ? "Clipboard history is empty" : "No matching items",
                    systemImage: "clipboard",
                    description: Text(query.isEmpty ? "Copied text will appear here." : "Try another search.")
                )
                .padding(VisualConfiguration.emptyStatePadding)
                .accessibilityIdentifier("clipboard-empty-state")
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        Button {
                            store.restore(entry)
                            onRestore()
                        } label: {
                            HStack(spacing: VisualConfiguration.rowSpacing) {
                                if let url = store.imageURL(for: entry), let image = NSImage(contentsOf: url) {
                                    Image(nsImage: image)
                                        .resizable().scaledToFill()
                                        .frame(width: VisualConfiguration.thumbnailSize.width,
                                               height: VisualConfiguration.thumbnailSize.height)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else if let fileURL = store.fileURL(for: entry) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: fileURL.path))
                                        .resizable().scaledToFit()
                                        .frame(width: VisualConfiguration.thumbnailSize.width,
                                               height: VisualConfiguration.thumbnailSize.height)
                                }
                                VStack(alignment: .leading, spacing: VisualConfiguration.rowSpacing) {
                                    Text(entry.preview).lineLimit(2)
                                    Text(entry.createdAt, style: .relative)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Restore \(entry.preview) to the clipboard")
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { filteredEntries[$0].id }
                        let sourceOffsets = IndexSet(store.entries.indices.filter { ids.contains(store.entries[$0].id) })
                        store.delete(at: sourceOffsets)
                    }
                }
            }
        }
        .padding()
    }
}
