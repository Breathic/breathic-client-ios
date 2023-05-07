import SwiftUI
import Foundation

struct ContentView: View {
    @ObservedObject private var store: Store = .shared

    @Environment(\.scenePhase) private var scenePhase

    let player = Player()

    init() {
        for metric in METRIC_TYPES.keys {
            if store.state.overviewMetricsVisibility[metric] == nil {
                store.state.overviewMetricsVisibility[metric] = METRIC_TYPES[metric]?.isChartable
            }
        }
    }

    var body: some View {
        var activeSubView = store.state.activeSubView
        var canShowToolbar: Bool = true

        if store.state.isTermsApproved == nil {
            activeSubView = SubView.Terms.rawValue
            canShowToolbar = false
        }

        if store.state.isGuideSeen == nil {
            activeSubView = SubView.Guide.rawValue
            canShowToolbar = false
        }

        if activeSubView == SubView.Save.rawValue {
            canShowToolbar = false
        }

        return ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack() {
                    Spacer(minLength: 4)

                    switch activeSubView {
                        case SubView.Guide.rawValue:
                            GuideView(
                                geometry: geometry,
                                store: store
                            )

                        case SubView.Terms.rawValue:
                            TermsView(
                                geometry: geometry,
                                store: store
                            )

                        case SubView.Menu.rawValue:
                            menuView(
                                geometry: geometry,
                                store: store,
                                tempActiveSubView: $store.state.tempActiveSubView
                            )

                        case SubView.Controller.rawValue, SubView.Status.rawValue:
                            if store.state.activeSession.isStarted() {
                                dragView(
                                    children: Group {
                                        HStack {
                                            controllerView(geometry: geometry, store: store, player: player, volume: $store.state.activeSession.volume)
                                            AnyView(statusView(geometry: geometry, store: store))
                                        }
                                        .onAppear {
                                            store.state.page = DEFAULT_PAGE
                                        }
                                    },
                                    geometry: geometry,
                                    store: store
                                )
                            }
                            else {
                                controllerView(geometry: geometry, store: store, player: player, volume: $store.state.activeSession.volume)
                            }

                        case SubView.Activity.rawValue:
                            activityPickerView(
                                geometry: geometry,
                                store: store,
                                player: player,
                                selectedActivityId: $store.state.selectedActivityId
                            )

                        case SubView.Log.rawValue:
                            logPickerView(
                                geometry: geometry,
                                store: store,
                                selectedSessionId: $store.state.selectedSessionId
                            )

                        case SubView.Finish.rawValue:
                            finishView(
                                geometry: geometry,
                                store: store,
                                player: player
                            )

                        case SubView.Save.rawValue:
                            savingView(
                                geometry: geometry,
                                store: store
                            )

                        case SubView.Discard.rawValue:
                            DiscardSessionConfirmationView(
                                geometry: geometry,
                                store: store,
                                player: player
                            )

                        case SubView.Delete.rawValue:
                            DeleteSessionConfirmationView(
                                geometry: geometry,
                                store: store
                            )

                        case store.state.selectedSessionId, SubView.Settings.rawValue:
                            chartSettingsView(geometry: geometry, store: store)

                        default:
                            Group {}
                    }
                }

                if (
                    (store.state.page == "Main" && store.state.activeSession.isStarted() &&
                        activeSubView == SubView.Controller.rawValue || activeSubView == SubView.Status.rawValue)
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
        .toolbar(content: { canShowToolbar ? toolbarView(store: store) : nil }
    ).onChange(of: scenePhase) { newPhase in
        if newPhase == .active {
            player.putToBackground(store: store)
        }
    }}
}
