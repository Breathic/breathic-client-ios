import SwiftUI
import Foundation

struct ContentView: View {
    @ObservedObject private var store: Store = .shared

    let player = Player()

    init() {
        clearTimeseries(store: store)
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack() {
                    Spacer(minLength: 4)

                    switch(store.state.activeSubView) {
                        case "Menu":
                            menuView(geometry: geometry, store: store, tempActiveSubView: $store.state.tempActiveSubView)

                        case MAIN_MENU_VIEWS[0], "Controller", "Status":
                            dragView(geometry: geometry,store: store, player: player, volume: $store.state.session.volume)

                        case "Log":
                            logView(geometry: geometry, store: store, selectedSessionId: $store.state.selectedSessionId)

                        case "Rhythm":
                            rhythmView(geometry: geometry, store: store, inRhythm: $store.state.session.inRhythm, outRhythm: $store.state.session.outRhythm)

                        case "Confirm":
                            sessionStopConfirmationView(geometry: geometry, store: store, player: player)

                        case "Delete":
                            deleteSessionConfirmationView(geometry: geometry, store: store)

                        case store.state.selectedSessionId:
                            overviewView(geometry: geometry, store: store)

                        default:
                            Group {}
                    }
                }
                .font(.system(size: store.state.ui.secondaryTextSize))

                if store.state.activeSubView == MAIN_MENU_VIEWS[0] || store.state.activeSubView == "Controller" || store.state.activeSubView == "Status" {
                    ZStack {
                        HStack {
                            DottedIndicator(index: store.state.dragIndex, maxIndex: 1, direction: "horizontal")
                        }
                        .frame(height: geometry.size.height + 20, alignment: .bottom)
                    }
                    .frame(width: geometry.size.width, alignment: .center)
                }
            }
        }.toolbar(content: { toolbarView(store: store) }
    )}
}
