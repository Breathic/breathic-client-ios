import SwiftUI

func chartSettingsView(
    geometry: GeometryProxy,
    store: Store
) -> some View {
    let columns = METRIC_ORDER
        .filter { store.state.chartableMetrics[$0] != nil }
        .chunks(2)
    let readingsURL: String = API_URL + "/session/" + store.state.selectedSession.uuid + "/readings"

    if Platform.isSimulator {
        print(readingsURL)
    }

    return ScrollView(showsIndicators: false) {
        Group {
            HStack {
                VStack {
                    Text("Duration")
                        .foregroundColor(Color.white)
                        .font(.system(size: 10))
                        .frame(maxWidth: geometry.size.width / 2, alignment: .leading)

                    Text(getElapsedTime(store.state.selectedSession.elapsedSeconds))
                        .foregroundColor(Color.white)
                        .font(.system(size: 20))
                        .frame(maxWidth: geometry.size.width / 2, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                VStack {
                    Text("Distance")
                        .foregroundColor(Color.white)
                        .font(.system(size: 10))
                        .frame(maxWidth: geometry.size.width / 2, alignment: .leading)

                    Text(String(format: "%.1f", store.state.selectedSession.distance / 1000) + "km")
                        .foregroundColor(Color.white)
                        .font(.system(size: 20))
                        .frame(maxWidth: geometry.size.width / 2, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.trailing, 16)

            Spacer(minLength: 24)
        }

        Group {
            HStack {
                VStack {
                    Text("Status")
                        .foregroundColor(Color.white)
                        .font(.system(size: 10))
                        .frame(maxWidth: geometry.size.width, alignment: .leading)

                    Text(store.state.selectedSession.syncStatus.rawValue)
                        .foregroundColor(Color.white)
                        .font(.system(size: 20))
                        .frame(maxWidth: geometry.size.width, alignment: .leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        Group {
            Text("Progress")
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)

            chart(
                geometry: geometry,
                seriesData: store.state.seriesData,
                chartDomain: store.state.chartDomain,
                action: {
                    store.state.chartScales.keys.forEach {
                        store.state.chartScales[$0] = !store.state.chartScales[$0]!
                    }
 
                    onLogSelect(store: store)
                }
            )

            Spacer(minLength: 24)
        }

        Group {
            Text("Legend")
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack {
                ForEach(columns, id: \.self) { column in
                    HStack {
                        ForEach(column, id: \.self) { metric in
                            primaryButton(
                                geometry: geometry,
                                label: getMetric(metric).label,
                                value: String(format: getMetric(metric).format, store.state.chartableMetrics[metric]!),
                                unit: getMetric(metric).unit,
                                valueColor: store.state.chartedMetricsVisibility[metric]!
                                    ? getMetric(metric).color
                                    : colorize("gray"),
                                valueTextSize: 32,
                                isShort: false,
                                isTall: true,
                                minimumScaleFactor: 0.5,
                                action: {
                                    store.state.chartedMetricsVisibility[metric]! = !store.state.chartedMetricsVisibility[metric]!
                                    onLogSelect(store: store)
                                }
                            )

                            Spacer(minLength: 8)
                        }
                    }.frame(width: geometry.size.width + 8)

                    Spacer(minLength: 8)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 24)
        }

        if store.state.selectedSession.syncStatus == SyncStatus.Synced {
            Group {
                Text("Export")
                    .font(.system(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)

                qrCode(geometry: geometry, url: readingsURL)

                Spacer(minLength: 24)
            }
        }

        Group {
            Text("Danger Zone")
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)

            secondaryButton(text: "Delete", color: "red", action: { store.state.activeSubView = SubView.Delete.rawValue })
                .frame(minWidth: geometry.size.width, maxHeight: .infinity, alignment: .bottom)
                .padding(.trailing, 16)
        }
    }
    .edgesIgnoringSafeArea(.all)
}
