import SwiftUI

@main
struct OdysseusApp: App {
    @StateObject private var store = OdysseusStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
