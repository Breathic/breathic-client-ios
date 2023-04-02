import SwiftUI

func controllerView(
    geometry: GeometryProxy,
    store: Store,
    player: Player,
    volume: Binding<Float>
) -> some View {
    VStack {
        HStack {
            primaryButton(
                geometry: geometry,
                label: "Session",
                value: !store.state.activeSession.isStarted()
                    ? "Start"
                    : "Finish",
                isTall: false,
                minimumScaleFactor: 0.75,
                action: {
                    if !store.state.activeSession.isStarted() {
                        store.state.selectedActivityId = ACTIVITIES[0].key
                        store.state.activeSubView = SubView.Activity.rawValue
                    }
                    else { store.state.activeSubView = SubView.Finish.rawValue }
                }
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Playback",
                value: store.state.activeSession.isStarted()
                    ? getElapsedTime(store.state.activeSession.elapsedSeconds)
                    : "",
                unit: store.state.activeSession.isPlaying
                    ? "Pause"
                    : "Play",
                isTall: false,
                isEnabled: store.state.activeSession.isStarted(),
                isBlurred: !store.state.activeSession.isStarted(),
                minimumScaleFactor: 0.75,
                action: {
                    if store.state.activeSession.isStarted() {
                        player.togglePlay()
                    }
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
                isEnabled: store.state.activeSession.isStarted(),
                isBlurred: !store.state.activeSession.isStarted(),
                minimumScaleFactor: 0.75,
                action: {
                    if store.state.activeSession.isStarted() {
                        store.state.activeSession.feedbackModeIndex = store.state.activeSession.feedbackModeIndex + 1 < FEEDBACK_MODES.count
                        ? store.state.activeSession.feedbackModeIndex + 1
                        : 0
                        store.state.render()
                    }
                }
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Activity",
                value: ACTIVITIES[store.state.activeSession.activityIndex].presets[store.state.activeSession.presetIndex].key.capitalized,
                unit: ACTIVITIES[store.state.activeSession.activityIndex].label,
                isTall: false,
                isEnabled: store.state.activeSession.isStarted(),
                isBlurred: !store.state.activeSession.isStarted(),
                action: {
                    if store.state.activeSession.isStarted() {
                        incrementPreset(store)
                        store.state.render()
                    }
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
    .frame(minWidth: geometry.size.width)
}
