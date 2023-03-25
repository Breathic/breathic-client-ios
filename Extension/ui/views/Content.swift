import SwiftUI
import Foundation

struct ContentView: View {
    @ObservedObject private var store: Store = .shared

    @Environment(\.scenePhase) private var scenePhase

    let player = Player()

    init() {
        for metric in METRIC_TYPES.keys {
            if store.state.chartedMetricsVisibility[metric] == nil {
                store.state.chartedMetricsVisibility[metric] = METRIC_TYPES[metric]?.isChartable
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack() {
                    Spacer(minLength: 4)

                    switch store.state.activeSubView {
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
                                        controllerView(geometry: geometry, store: store, player: player, volume: $store.state.activeSession.volume)
                                        !isSessionActive(store: store)
                                            ? AnyView(introductionView(geometry: geometry, store: store))
                                            : AnyView(statusView(geometry: geometry, store: store))
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

                        case "Session":
                            sessionStopConfirmationView(
                                geometry: geometry,
                                store: store,
                                player: player
                            )

                        case "Discard":
                            DiscardSessionConfirmationView(
                                geometry: geometry,
                                store: store,
                                player: player
                            )

                        case "Delete":
                            DeleteSessionConfirmationView(
                                geometry: geometry,
                                store: store
                            )

                        case store.state.selectedSessionId, "Settings":
                            chartSettingsView(geometry: geometry, store: store)

                        default:
                            Group {}
                    }
                }

                if (
                    (store.state.page == "Main" &&
                        store.state.activeSubView == "Controller" || store.state.activeSubView == "Status")
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
        }
        .toolbar(content: { toolbarView(store: store) }
    ).onChange(of: scenePhase) { newPhase in
        if newPhase == .active {
            player.putToBackground(store: store)
        }
    }}
}
