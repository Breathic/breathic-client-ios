import SwiftUI

@main
struct pacemakerApp: App {
    @State private var store: AppStore = .shared

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .onScenePhaseChange(phase: .active) { store.state.scenePhase = .active }
                    .onScenePhaseChange(phase: .background) { store.state.scenePhase = .background }
                    .onScenePhaseChange(phase: .inactive) { store.state.scenePhase = .inactive }
            }
        }
    }
}
