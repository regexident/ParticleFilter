public struct MotionModel: Equatable {
    public var stdDeviation: Double
    
    public init(stdDeviation: Double) {
        self.stdDeviation = stdDeviation
    }
}

public struct ObservationModel: Equatable {
    public var stdDeviation: Double
    
    public init(stdDeviation: Double) {
        self.stdDeviation = stdDeviation
    }
}

public struct EvaluationModel: Equatable {
    public var threshold: Double
    
    public init(threshold: Double = 0.5) {
        self.threshold = threshold
    }
}

public struct Model: Equatable {
    public var motion: MotionModel
    public var observation: ObservationModel
    public var evaluation: EvaluationModel
    
    public init(
        motion: MotionModel,
        observation: ObservationModel,
        evaluation: EvaluationModel
    ) {
        self.motion = motion
        self.observation = observation
        self.evaluation = evaluation
    }
}
