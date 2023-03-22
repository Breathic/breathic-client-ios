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
                value: METRIC_TYPES[getSourceMetricTypes()[store.state.session.metricTypeIndex]]!.label,
                valueColor: isSessionActive(store: store)
                    ? METRIC_TYPES[getSourceMetricTypes()[store.state.session.metricTypeIndex]]!.color
                    : colorize("white"),
                isShort: true,
                isTall: false,
                minimumScaleFactor: 0.5,
                action: {
                    let sourceMetricTypes: [String] = getSourceMetricTypes()

                    store.state.session.metricTypeIndex = store.state.session.metricTypeIndex + 1 < sourceMetricTypes.count
                        ? store.state.session.metricTypeIndex + 1
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
                    if !store.state.session.isActive || store.state.isResumable { player.start() }
                    else { store.state.activeSubView = "Session" }
                }
            )
        }

        Spacer(minLength: 8)

        HStack {
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
                isShort: true,
                isTall: false,
                minimumScaleFactor: 0.75,
                action: {
                    store.state.session.feedbackModeIndex = store.state.session.feedbackModeIndex + 1 < FEEDBACK_MODES.count
                        ? store.state.session.feedbackModeIndex + 1
                        : 0
                    store.state.render()
                }
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Activity",
                value: ACTIVITIES[store.state.session.activityIndex].presets[store.state.session.presetIndex].key.capitalized,
                unit: ACTIVITIES[store.state.session.activityIndex].label,
                isTall: false,
                action: {
                    incrementPreset(store)
                    store.state.render()
                },
                longAction: {
                    store.state.session.activityIndex = store.state.session.activityIndex + 1 < ACTIVITIES.count
                        ? store.state.session.activityIndex + 1
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
    .onChange(of: store.state.session.volume) { value in
        if value < VOLUME_RANGE[0] {
            store.state.session.volume = VOLUME_RANGE[0]
        }
        else if value > VOLUME_RANGE[1] {
            store.state.session.volume = VOLUME_RANGE[1]
        }
    }
}
