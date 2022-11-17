import SwiftUI
import Foundation

struct ContentView: View {
    @ObservedObject private var store: Store = .shared

    let player = Player()

    init() {
        for metric in METRIC_TYPES.keys {
            if store.state.chartedMetricsVisivbility[metric] == nil {
                store.state.chartedMetricsVisivbility[metric] = true
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack() {
                    Spacer(minLength: 4)

                    switch(store.state.activeSubView) {
                        case "Menu":
                            menuView(
                                geometry: geometry,
                                store: store,
                                tempActiveSubView: $store.state.tempActiveSubView
                            )

                        case "Controller", "Status":
                            dragView(
                                children: Group {
                                    HStack {
                                        controllerView(geometry: geometry, store: store, player: player, volume: $store.state.session.volume)
                                        statusView(geometry: geometry, store: store)
                                    }
                                    .onAppear {
                                        store.state.page = DEFAULT_PAGE
                                    }
                                },
                                geometry: geometry,
                                store: store
                            )

                        case "Log":
                            logView(
                                geometry: geometry,
                                store: store,
                                selectedSessionId: $store.state.selectedSessionId
                            )

                        case "Rhythm":
                            rhythmView(
                                geometry: geometry,
                                store: store,
                                inRhythm: $store.state.session.inRhythm,
                                outRhythm: $store.state.session.outRhythm
                            )

                        case "Confirm":
                            sessionStopConfirmationView(
                                geometry: geometry,
                                store: store,
                                player: player
                            )

                        case "Delete":
                            deleteSessionConfirmationView(
                                geometry: geometry,
                                store: store
                            )

                        case store.state.selectedSessionId, "Settings":
                            dragView(
                                children: Group {
                                    HStack {
                                        chartSettingsView(geometry: geometry, store: store)
                                        overviewView(geometry: geometry, store: store)
                                    }
                                    .onAppear {
                                        store.state.menuViews["Overview"]![0] = store.state.selectedSessionId
                                        store.state.menuViews["Overview"]![1] = store.state.selectedSessionId
                                        store.state.page = "Overview"
                                    }
                                    .onDisappear {
                                        store.state.pageOptions[store.state.page]! = PageOption()
                                        store.state.page = DEFAULT_PAGE
                                    }
                                },
                                geometry: geometry,
                                store: store
                            )

                        default:
                            Group {}
                    }
                }
                .font(.system(size: store.state.ui.secondaryTextSize))

                if (
                    (store.state.page == "Main" &&
                        store.state.activeSubView == "Controller" || store.state.activeSubView == "Status") ||
                    (store.state.page == "Overview")
                ) {
                    ZStack {
                        HStack {
                            DottedIndicator(index: store.state.pageOptions[store.state.page]!.dragIndex, maxIndex: 1, direction: "horizontal")
                        }
                        .frame(height: geometry.size.height + 20, alignment: .bottom)
                    }
                    .frame(width: geometry.size.width, alignment: .center)
                }
            }
        }.toolbar(content: { toolbarView(store: store) }
    )}
}
