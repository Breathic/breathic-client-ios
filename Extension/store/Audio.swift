class Audio {
    var fadeIndex: Int = 0
    var sampleIndex: Int = 0
    var channels: [[String]] = []
    var forResources: [String] = []

    init(
        fadeIndex: Int,
        sampleIndex: Int,
        channels: [[String]],
        forResources: [String]
    ) {
        self.fadeIndex = fadeIndex
        self.sampleIndex = sampleIndex
        self.channels = channels
        self.forResources = forResources
    }

    func copy() -> Any {
        let copy: Audio = Audio(
            fadeIndex: fadeIndex,
            sampleIndex: sampleIndex,
            channels: channels,
            forResources: forResources
        )
        return copy
    }
}
