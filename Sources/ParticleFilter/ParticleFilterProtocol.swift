import Foundation

import particle_filter

public enum ParticleFilterEvaluation {
    case healthy
    case impoverished
}

public struct ParticleFilterOutput {
    let estimate: Double3
    let particles: [Particle]
    let variance: Double
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
        didEstimate coordinate: Double3
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
