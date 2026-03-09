import SwiftUI

/// Main app entry point for TipFlow.
@main
struct TipFlowApp: App {
    @StateObject private var shiftViewModel = ShiftViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(shiftViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
