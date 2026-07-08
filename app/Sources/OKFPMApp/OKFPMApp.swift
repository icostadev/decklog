import SwiftUI

@main
struct OKFPMApp: App {
    @StateObject private var store = BundleStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 560)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Bundle…") { store.openBundle() }
                    .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}
