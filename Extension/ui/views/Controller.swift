import SwiftUI

func controllerView(
    geometry: GeometryProxy,
    store: Store,
    player: Player,
    volume: Binding<Float>
) -> some View {
    func getSessionValue(store: Store) -> String {
        if store.state.activeSession.isStarted() {
            if store.state.activeSession.isPlaying { return getElapsedTime(store.state.activeSession.elapsedSeconds) }
            else { return "Resume" }
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
                value: METRIC_TYPES[getSourceMetricTypes()[store.state.activeSession.metricTypeIndex]]!.label,
                valueColor: isSessionActive(store: store)
                    ? METRIC_TYPES[getSourceMetricTypes()[store.state.activeSession.metricTypeIndex]]!.color
                    : colorize("white"),
                isShort: true,
                isTall: false,
                minimumScaleFactor: 0.5,
                action: {
                    let sourceMetricTypes: [String] = getSourceMetricTypes()

                    store.state.activeSession.metricTypeIndex = store.state.activeSession.metricTypeIndex + 1 < sourceMetricTypes.count
                        ? store.state.activeSession.metricTypeIndex + 1
                        : 0
                    store.state.setMetricValuesToDefault()
                    store.state.render()
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
                    if !store.state.activeSession.isStarted() { player.start() }
                    else { store.state.activeSubView = "Session" }
                }
            )
        }

        Spacer(minLength: 8)

        HStack {
            primaryButton(
                geometry: geometry,
                label: "Feedback",
                value: FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex].rawValue.capitalized,
                hasIndicator: true,
                index: Int(ceil(
                    convertRange(
                        value: Float(store.state.activeSession.volume),
                        oldRange: [Float(VOLUME_RANGE[0]), Float(VOLUME_RANGE[1])],
                        newRange: [Float(0), Float(10)]
                    )) - 1
                ),
                maxIndex: FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.Audio || FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.AudioHaptic
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
                    store.state.activeSession.feedbackModeIndex = store.state.activeSession.feedbackModeIndex + 1 < FEEDBACK_MODES.count
                        ? store.state.activeSession.feedbackModeIndex + 1
                        : 0
                    store.state.render()
                }
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Activity",
                value: ACTIVITIES[store.state.activeSession.activityIndex].presets[store.state.activeSession.presetIndex].key.capitalized,
                unit: ACTIVITIES[store.state.activeSession.activityIndex].label,
                isTall: false,
                action: {
                    incrementPreset(store)
                    store.state.render()
                },
                longAction: {
                    store.state.activeSession.activityIndex = store.state.activeSession.activityIndex + 1 < ACTIVITIES.count
                        ? store.state.activeSession.activityIndex + 1
                        : 0
                    store.state.render()
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
    .onChange(of: store.state.activeSession.volume) { value in
        if value < VOLUME_RANGE[0] {
            store.state.activeSession.volume = VOLUME_RANGE[0]
        }
        else if value > VOLUME_RANGE[1] {
            store.state.activeSession.volume = VOLUME_RANGE[1]
        }
    }
}
