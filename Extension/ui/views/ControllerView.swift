import SwiftUI

func controllerView(
    geometry: GeometryProxy,
    store: Store,
    player: Player,
    volume: Binding<Float>
) -> some View {
    func getSessionValue(store: Store) -> String {
        if store.state.session.isActive {
            if store.state.isResumable { return "Resume" }
            if !store.state.session.isPlaying { return "Paused" }
            else if store.state.elapsedTime.count > 0 { return store.state.elapsedTime }
            else { return "" }
        }
        else {
            return "Stopped"
        }
    }

    return VStack {
        HStack {
            primaryButton(
                geometry: geometry,
                label: "Source",
                value: store.state.metricType.label,
                valueColor: store.state.metricType.color,
                isShort: true,
                isTall: false,
                minimumScaleFactor: 0.5,
                action: {
                    let sourceMetricTypes: [String] = METRIC_TYPES.keys.filter {
                        METRIC_TYPES[$0]!.isSource
                    }

                    store.state.session.metricTypeIndex = store.state.session.metricTypeIndex + 1 < sourceMetricTypes.count
                        ? store.state.session.metricTypeIndex + 1
                        : 0
                    store.state.metricType = METRIC_TYPES[sourceMetricTypes[store.state.session.metricTypeIndex]]!
                    store.state.setMetricValuesToDefault()
                }
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Rhythm",
                value: "\(String(format: "%.1f", Double(store.state.session.inRhythm))):\(String(format: "%.1f", Double(store.state.session.outRhythm)))",
                valueColor: store.state.metricType.color,
                isTall: false,
                action: { store.state.activeSubView = "Rhythm" }
            )
        }

        Spacer(minLength: 8)

        HStack {
            primaryButton(
                geometry: geometry,
                label: "Session",
                value: getSessionValue(store: store),
                isTall: false,
                action: {
                    player.togglePlay()
                },
                longAction: {
                    if !store.state.session.isActive || store.state.isResumable { player.start() }
                    else { store.state.activeSubView = "Confirm" }
                }
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Feedback",
                value: FEEDBACK_MODES[store.state.session.feedbackModeIndex],
                hasIndicator: true,
                index: Int(ceil(
                    convertRange(
                        value: Float(store.state.session.volume),
                        oldRange: [Float(VOLUME_RANGE[0]), Float(VOLUME_RANGE[1])],
                        newRange: [Float(0), Float(10)]
                    )) - 1
                ),
                maxIndex: FEEDBACK_MODES[store.state.session.feedbackModeIndex] == "Audio"
                    ? Int(ceil(
                        convertRange(
                            value: Float(VOLUME_RANGE[1]),
                            oldRange: [Float(VOLUME_RANGE[0]), Float(VOLUME_RANGE[1])],
                            newRange: [Float(0), Float(10)]
                        )) - 1)
                    : 0,
                valueColor: store.state.metricType.color,
                isShort: true,
                isTall: false,
                isEnabled: isSessionActive(store: store),
                opacity: isSessionActive(store: store) ? 1 : 0.33,
                minimumScaleFactor: 0.75,
                action: {
                    store.state.session.feedbackModeIndex = store.state.session.feedbackModeIndex + 1 < FEEDBACK_MODES.count
                        ? store.state.session.feedbackModeIndex + 1
                        : 0
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
