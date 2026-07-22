import SwiftUI

struct ContentView: View {
    var body: some View {
        ContentUnavailableView(
            "Clipboard history is empty",
            systemImage: "clipboard",
            description: Text("Clipboard monitoring will be added in the next milestone.")
        )
        .padding(VisualConfiguration.emptyStatePadding)
        .accessibilityIdentifier("clipboard-empty-state")
    }
}
