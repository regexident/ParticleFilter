public struct MotionModel: Equatable {
    public var stdDeviation: Double = 0.0
}

public struct ObservationModel: Equatable {
    public var stdDeviation: Double = 0.0
}

public struct EvaluationModel: Equatable {
    public var threshold: Double = 0.5
}

public struct Model: Equatable {
    public var motion: MotionModel = .init()
    public var observation: ObservationModel = .init()
    public var evaluation: EvaluationModel = .init()
}
