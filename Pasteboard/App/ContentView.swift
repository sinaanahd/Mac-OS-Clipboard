import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ClipboardHistoryStore
    var onRestore: () -> Void = {}
    @State private var query = ""

    private var filteredEntries: [ClipboardEntry] {
        query.isEmpty ? store.entries : store.entries.filter {
            $0.text.localizedCaseInsensitiveContains(query)
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
                            VStack(alignment: .leading, spacing: VisualConfiguration.rowSpacing) {
                                Text(entry.preview).lineLimit(2)
                                Text(entry.createdAt, style: .relative)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy \(entry.preview) back to the clipboard")
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
