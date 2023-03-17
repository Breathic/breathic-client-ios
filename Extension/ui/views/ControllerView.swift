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
            if !store.state.session.isPlaying { return "Unpause" }
            else if store.state.elapsedTime.count > 0 { return store.state.elapsedTime }
            else { return "" }
        }
        else {
            return "Start"
        }
    }

    return VStack {
        HStack {
            primaryButton(
                geometry: geometry,
                label: "Source",
                value: store.state.metricType.label,
                valueColor: isSessionActive(store: store)
                    ? store.state.metricType.color
                    : colorize("white"),
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

                    uploadSession(session: store.state.sessionLogs.reversed()[0])
                }
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Session",
                value: getSessionValue(store: store),
                isTall: false,
                minimumScaleFactor: 0.75,
                action: {
                    player.togglePlay()
                },
                longAction: {
                    if !store.state.session.isActive || store.state.isResumable { player.start() }
                    else { store.state.activeSubView = "Confirm" }
                }
            )
        }

        Spacer(minLength: 8)

        HStack {
            primaryButton(
                geometry: geometry,
                label: "Feedback",
                value: store.state.feedbackMode,
                /*
                unit: store.state.feedbackMode == "Audio"
                    ? store.state.audioPanningMode
                    : "",
                */
                hasIndicator: true,
                index: Int(ceil(
                    convertRange(
                        value: Float(store.state.session.volume),
                        oldRange: [Float(VOLUME_RANGE[0]), Float(VOLUME_RANGE[1])],
                        newRange: [Float(0), Float(10)]
                    )) - 1
                ),
                maxIndex: store.state.feedbackMode == "Audio"
                    ? Int(ceil(
                        convertRange(
                            value: Float(VOLUME_RANGE[1]),
                            oldRange: [Float(VOLUME_RANGE[0]), Float(VOLUME_RANGE[1])],
                            newRange: [Float(0), Float(10)]
                        )) - 1)
                    : 0,
                isShort: true,
                isTall: false,
                minimumScaleFactor: 0.75,
                action: {
                    store.state.session.feedbackModeIndex = store.state.session.feedbackModeIndex + 1 < FEEDBACK_MODES.count
                        ? store.state.session.feedbackModeIndex + 1
                        : 0
                    store.state.feedbackMode = FEEDBACK_MODES[store.state.session.feedbackModeIndex]
                }
                /*
                longAction: {
                    if store.state.feedbackMode == "Audio" {
                        store.state.session.audioPanningIndex = store.state.session.audioPanningIndex + 1 < AUDIO_PANNING_MODES.count
                            ? store.state.session.audioPanningIndex + 1
                            : 0
                        store.state.audioPanningMode = AUDIO_PANNING_MODES[store.state.session.audioPanningIndex]
                    }
                }
                */
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Activity",
                value: store.state.preset.key.capitalized,
                unit: store.state.activity.label,
                isTall: false,
                action: {
                    incrementPreset(store)
                },
                longAction: {
                    let activityKeys: [String] = ACTIVITIES.map { $0.key }
                    let currentActivityKey = store.state.session.activityKey
                    let currentActivityIndex = activityKeys.firstIndex { $0 == currentActivityKey } ?? -1
                    let newActivityIndex = currentActivityIndex + 1 == activityKeys.count
                        ? 0
                        : currentActivityIndex + 1
                    let newActivityKey = activityKeys[newActivityIndex]

                    store.state.session.presetIndex = -1
                    incrementPreset(store)
                    store.state.session.activityKey = newActivityKey
                    store.state.activity = ACTIVITIES[newActivityIndex]
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
