class Audio {
    var fadeIndex: Int = 0
    var sampleIndex: Int = 0
    var channels: [[String]] = []
    var resources: [String] = []

    init(

        fadeIndex: Int,
        sampleIndex: Int,
        channels: [[String]],
        resources: [String]
    ) {

        self.fadeIndex = fadeIndex
        self.sampleIndex = sampleIndex
        self.channels = channels
        self.resources = resources
    }

    func copy() -> Any {
        Audio(
            fadeIndex: fadeIndex,
            sampleIndex: sampleIndex,
            channels: channels,
            resources: resources
        )
    }
}
