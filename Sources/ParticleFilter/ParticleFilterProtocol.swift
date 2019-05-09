import Foundation

import particle_filter

public enum ParticleFilterEvaluation {
    case healthy
    case impoverished
}

public struct ParticleFilterEstimate {
    public let mean: Double3
    public let variance: Double
}

public struct ParticleFilterOutput {
    public let estimate: ParticleFilterEstimate
    public let particles: [Particle]
}

public protocol ParticleFilterDelegate: class {
    func particleFilter(
        _ particleFilter: ParticleFilterProtocol,
        didPredict particles: [Particle]
    )

    func particleFilter(
        _ particleFilter: ParticleFilterProtocol,
        didWeight particles: [Particle]
    )

    func particleFilter(
        _ particleFilter: ParticleFilterProtocol,
        didEvaluate evaluation: ParticleFilterEvaluation
    )

    func particleFilter(
        _ particleFilter: ParticleFilterProtocol,
        didResample particles: [Particle]
    )

    func particleFilter(
        _ particleFilter: ParticleFilterProtocol,
        didCalculateMean mean: Double3
    )

    func particleFilter(
        _ particleFilter: ParticleFilterProtocol,
        didCalculateVariance variance: Double
    )
}

public protocol ParticleFilterProtocol {
    func filter(
        particles: [Particle],
        observations: [Observation],
        model: Model,
        control: Double3
    ) -> ParticleFilterOutput
}
