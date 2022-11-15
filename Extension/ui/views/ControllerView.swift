import SwiftUI

func controllerView(
    geometry: GeometryProxy,
    store: Store,
    player: Player,
    volume: Binding<Float>
) -> some View {
    VStack() {
        HStack {
            primaryButton(
                geometry: geometry,
                label: "Pace",
                value: store.state.metricType.label,
                unit: "per " + store.state.metricType.unit,
                valueColor: METRIC_COLORS[store.state.metricType.metric]!,
                isShort: true,
                isTall: false,
                action: {
                    store.state.session.metricTypeIndex = store.state.session.metricTypeIndex + 1 < METRIC_TYPES.count
                        ? store.state.session.metricTypeIndex + 1
                        : 0
                    store.state.metricType = METRIC_TYPES[store.state.session.metricTypeIndex]
                    store.state.metrics = DEFAULT_METRICS
                }
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Rhythm",
                value: "\(String(format: "%.1f", Double(store.state.session.inRhythm) / 10)):\(String(format: "%.1f", Double(store.state.session.outRhythm) / 10))",
                unit: "per pace",
                valueColor: METRIC_COLORS[store.state.metricType.metric]!,
                isTall: false,
                action: { store.state.activeSubView = "Rhythm" }
            )
        }

        Spacer(minLength: 8)

        HStack {
            primaryButton(
                geometry: geometry,
                label: "Session",
                value: store.state.session.isActive
                    ? "⚑"
                    : "◴",
                unit: getSessionUnit(store: store),
                isTall: false,
                action: {
                    if !store.state.session.isActive || store.state.isResumable { player.start() }
                    else { store.state.activeSubView = "Confirm" }
                }
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Audio",
                value: store.state.isAudioSessionLoaded
                    ? "||"
                    : "▶",
                unit: store.state.isAudioSessionLoaded
                    ? Float(store.state.session.volume) > 0
                        ? "Playing"
                        : "Muted"
                    : "Paused",
                index: Int(ceil(
                    convertRange(
                        value: Float(store.state.session.volume),
                        oldRange: [Float(VOLUME_RANGE[0]), Float(VOLUME_RANGE[1])],
                        newRange: [Float(0), Float(10)]
                    )) - 1
                ),
                maxIndex: Int(ceil(
                    convertRange(
                        value: Float(VOLUME_RANGE[1]),
                        oldRange: [Float(VOLUME_RANGE[0]), Float(VOLUME_RANGE[1])],
                        newRange: [Float(0), Float(10)]
                    )) - 1
                ),
                isTall: false,
                isEnabled: isSessionActive(store: store),
                opacity: isSessionActive(store: store) ? 1 : 0.33,
                action: {
                    player.togglePlay()
                }
            )
        }
    }
    .focusable()
    .digitalCrownRotation(
        volume,
        from: VOLUME_RANGE[0] - (VOLUME_RANGE[1] * CROWN_MULTIPLIER),
        through: VOLUME_RANGE[1] + (VOLUME_RANGE[1] * CROWN_MULTIPLIER),
        by: VOLUME_RANGE[1] / 100 * 3 * CROWN_MULTIPLIER,
        sensitivity: .high,
        isContinuous: true,
        isHapticFeedbackEnabled: true
    )
    .onChange(of: store.state.session.volume) { value in
        if value < VOLUME_RANGE[0] {
            store.state.session.volume = VOLUME_RANGE[0]
        }
        else if value > VOLUME_RANGE[1] {
            store.state.session.volume = VOLUME_RANGE[1]
        }
    }
}
