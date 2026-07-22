import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ClipboardHistoryStore
    @ObservedObject var presentation: HistoryPanelPresentation
    var onRestore: () -> Void = {}
    @State private var query = ""

    private var filteredEntries: [ClipboardEntry] {
        query.isEmpty ? store.entries : store.entries.filter {
            $0.preview.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VisualConfiguration.searchFieldSpacing) {
            HStack(alignment: .top, spacing: VisualConfiguration.headerSpacing) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: VisualConfiguration.headerIconSize,
                           height: VisualConfiguration.headerIconSize)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(AppConfiguration.productName)
                        .font(.headline)
                    Text("Clipboard History")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Version \(AppConfiguration.marketingVersion)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Pasteboard version \(AppConfiguration.marketingVersion)")
            }

            HistorySearchField(text: $query, prompt: "Search clipboard history")
                .accessibilityLabel("Search clipboard history")
            if filteredEntries.isEmpty {
                ContentUnavailableView(
                    query.isEmpty ? "Clipboard history is empty" : "No matching items",
                    systemImage: "clipboard",
                    description: Text(query.isEmpty ? "Copied text will appear here." : "Try another search.")
                )
                .padding(VisualConfiguration.emptyStatePadding)
                .accessibilityIdentifier("clipboard-empty-state")
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(filteredEntries) { entry in
                            HStack(spacing: VisualConfiguration.rowSpacing) {
                                Button {
                                    store.restore(entry)
                                    onRestore()
                                } label: {
                                    entryLabel(entry)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Restore \(entry.preview) to the clipboard")

                                Button {
                                    store.togglePin(id: entry.id)
                                } label: {
                                    Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                                        .foregroundStyle(entry.isPinned ? Color.accentColor : Color.secondary)
                                        .frame(width: VisualConfiguration.rowActionSize,
                                               height: VisualConfiguration.rowActionSize)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .help(entry.isPinned ? "Unpin item" : "Pin item")
                                .accessibilityLabel(entry.isPinned ? "Unpin item" : "Pin item")
                            }
                            .id(entry.id)
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { filteredEntries[$0].id }
                            let sourceOffsets = IndexSet(store.entries.indices.filter { ids.contains(store.entries[$0].id) })
                            store.delete(at: sourceOffsets)
                        }
                    }
                    .onChange(of: filteredEntries.first?.id) { _, newestEntryID in
                        guard let newestEntryID else { return }
                        DispatchQueue.main.async {
                            proxy.scrollTo(newestEntryID, anchor: .top)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .padding(.top, VisualConfiguration.panelTopPadding)
        .ignoresSafeArea(.container, edges: .top)
        .onChange(of: store.entries.first?.id) { _, _ in
            presentation.refresh()
        }
    }

    @ViewBuilder
    private func entryLabel(_ entry: ClipboardEntry) -> some View {
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
                Text(HistoryRelativeTimeFormatter.string(
                    from: entry.createdAt,
                    relativeTo: presentation.referenceDate
                ))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct HistorySearchField: NSViewRepresentable {
    @Binding var text: String
    let prompt: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.placeholderString = prompt
        searchField.sendsSearchStringImmediately = true
        searchField.delegate = context.coordinator
        return searchField
    }

    func updateNSView(_ searchField: NSSearchField, context: Context) {
        context.coordinator.text = $text
        if searchField.stringValue != text {
            searchField.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let searchField = notification.object as? NSSearchField else { return }
            text.wrappedValue = searchField.stringValue
        }
    }
}
