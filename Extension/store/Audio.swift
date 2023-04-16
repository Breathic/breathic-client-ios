class Audio {
    var fadeIndex: Int = 0
    var sampleIndex: Int = 0
    var samples: [[String]] = []
    var resources: [String] = []

    init(
        fadeIndex: Int,
        sampleIndex: Int,
        samples: [[String]],
        resources: [String]
    ) {
        self.fadeIndex = fadeIndex
        self.sampleIndex = sampleIndex
        self.samples = samples
        self.resources = resources
    }

    func copy() -> Any {
        Audio(
            fadeIndex: fadeIndex,
            sampleIndex: sampleIndex,
            samples: samples,
            resources: resources
        )
    }
}
