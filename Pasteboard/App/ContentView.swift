import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ClipboardHistoryStore
    @ObservedObject var presentation: HistoryPanelPresentation
    let thumbnailService: ThumbnailService
    var onRestore: () -> Void = {}
    @State private var query = ""
    @FocusState private var isListFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var filteredEntries: [ClipboardEntry] {
        query.isEmpty ? store.entries : store.entries.filter {
            $0.preview.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VisualConfiguration.searchFieldSpacing) {
            VStack(spacing: VisualConfiguration.searchFieldSpacing) {
                HStack(alignment: .top, spacing: VisualConfiguration.headerSpacing) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: VisualConfiguration.headerIconSize,
                               height: VisualConfiguration.headerIconSize)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(AppConfiguration.productName).font(.headline)
                        Text("Clipboard History").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Version \(AppConfiguration.marketingVersion)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Pasteboard version \(AppConfiguration.marketingVersion)")
                }
                HistorySearchField(text: $query, prompt: "Search clipboard history")
                    .accessibilityLabel("Search clipboard history")
            }
            .pasteboardFunctionalSurface()
            if filteredEntries.isEmpty {
                VStack(spacing: VisualConfiguration.rowSpacing) {
                    Image(systemName: "clipboard")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(query.isEmpty ? "Clipboard history is empty" : "No matching items")
                        .font(.headline)
                    Text(query.isEmpty ? "Copied items will appear here." : "Try another search.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, VisualConfiguration.emptyStateTopPadding)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("clipboard-empty-state")
            } else {
                ScrollViewReader { proxy in
                    List(selection: $presentation.keyboardSelection) {
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
                                    withAnimation(interactionAnimation) {
                                        store.togglePin(id: entry.id)
                                    }
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
                            .tag(entry.id)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { filteredEntries[$0].id }
                            let sourceOffsets = IndexSet(store.entries.indices.filter { ids.contains(store.entries[$0].id) })
                            withAnimation(interactionAnimation) { store.delete(at: sourceOffsets) }
                        }
                    }
                    .focused($isListFocused)
                    .onChange(of: isListFocused) { _, focused in
                        presentation.setListFocused(focused)
                    }
                    .onMoveCommand(perform: moveKeyboardSelection)
                    .onKeyPress(.space) {
                        toggleKeyboardSelectionPin() ? .handled : .ignored
                    }
                    .onKeyPress(.delete) {
                        deleteKeyboardSelection() ? .handled : .ignored
                    }
                    .accessibilityHint(
                        "Use the arrow keys to select an item, Return to restore it, "
                        + "Space to pin or unpin it, and Delete to remove it."
                    )
                    .onChange(of: filteredEntries.first?.id) { _, newestEntryID in
                        guard let newestEntryID else { return }
                        DispatchQueue.main.async {
                            proxy.scrollTo(newestEntryID, anchor: .top)
                        }
                    }
                }
                .animation(interactionAnimation, value: filteredEntries.map(\.id))
                .onChange(of: filteredEntries.map(\.id)) { _, visibleIDs in
                    if let selection = presentation.keyboardSelection,
                       !visibleIDs.contains(selection) {
                        presentation.keyboardSelection = nil
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .padding(.top, VisualConfiguration.panelTopPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea(.container, edges: .top)
        .onChange(of: store.entries.first?.id) { _, _ in
            presentation.refresh()
        }
    }

    private var interactionAnimation: Animation {
        .easeOut(duration: reduceMotion ? 0.12 : VisualConfiguration.quickAnimationDuration)
    }

    private func moveKeyboardSelection(_ direction: MoveCommandDirection) {
        let navigationDirection: HistoryNavigationDirection
        switch direction {
        case .up:
            navigationDirection = .previous
        case .down:
            navigationDirection = .next
        default:
            return
        }
        presentation.keyboardSelection = HistoryKeyboardNavigation.movedSelection(
            current: presentation.keyboardSelection,
            ids: filteredEntries.map(\.id),
            direction: navigationDirection
        )
    }

    private func toggleKeyboardSelectionPin() -> Bool {
        guard let keyboardSelection = presentation.keyboardSelection,
              filteredEntries.contains(where: { $0.id == keyboardSelection }) else {
            return false
        }
        withAnimation(interactionAnimation) {
            store.togglePin(id: keyboardSelection)
        }
        return true
    }

    private func deleteKeyboardSelection() -> Bool {
        guard let keyboardSelection = presentation.keyboardSelection,
              let sourceIndex = store.entries.firstIndex(where: { $0.id == keyboardSelection }),
              let visibleIndex = filteredEntries.firstIndex(where: { $0.id == keyboardSelection })
        else {
            return false
        }

        let visibleIDs = filteredEntries.map(\.id)
        let nextSelection: ClipboardEntry.ID?
        if visibleIDs.indices.contains(visibleIndex + 1) {
            nextSelection = visibleIDs[visibleIndex + 1]
        } else if visibleIndex > visibleIDs.startIndex {
            nextSelection = visibleIDs[visibleIndex - 1]
        } else {
            nextSelection = nil
        }

        withAnimation(interactionAnimation) {
            store.delete(at: IndexSet(integer: sourceIndex))
        }
        presentation.keyboardSelection = nextSelection
        return true
    }

    @ViewBuilder
    private func entryLabel(_ entry: ClipboardEntry) -> some View {
        HStack(spacing: VisualConfiguration.rowSpacing) {
            if let url = store.imageURL(for: entry) {
                HistoryImageThumbnail(url: url, service: thumbnailService)
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

private extension View {
    @ViewBuilder
    func pasteboardFunctionalSurface() -> some View {
#if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            self.padding(10)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            pasteboardFallbackSurface()
        }
#else
        pasteboardFallbackSurface()
#endif
    }

    private func pasteboardFallbackSurface() -> some View {
        self.padding(10)
            .background(.ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
            }
    }
}

private struct HistoryImageThumbnail: View {
    let url: URL
    let service: ThumbnailService
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Loading image thumbnail")
            }
        }
        .frame(width: VisualConfiguration.thumbnailSize.width,
               height: VisualConfiguration.thumbnailSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .task(id: url) {
            image = await service.thumbnail(
                for: url,
                maxPixelSize: Int(max(VisualConfiguration.thumbnailSize.width,
                                      VisualConfiguration.thumbnailSize.height) * 2)
            )
        }
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
