class Audio {
    var fadeIndex: Int = 0
    var sampleIndex: Int = 0
    var resources: [String] = []

    init(
        fadeIndex: Int,
        sampleIndex: Int,
        resources: [String]
    ) {
        self.fadeIndex = fadeIndex
        self.sampleIndex = sampleIndex
        self.resources = resources
    }

    func copy() -> Any {
        Audio(
            fadeIndex: fadeIndex,
            sampleIndex: sampleIndex,
            resources: resources
        )
    }
}
