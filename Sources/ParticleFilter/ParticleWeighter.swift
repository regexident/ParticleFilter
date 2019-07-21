import Foundation

import Surge

internal struct ParticleWeighter: ParticleWeighterProtocol {
    internal typealias ParticleBuffer = [Particle]
    
    internal func weight(
        particles: ParticleBuffer,
        observations: [LandmarkObservation<Double>],
        model: ObservationModel
    ) -> ParticleBuffer {
        assert(!particles.isEmpty)
        let cdf = NormalCumulativeDistributionFunction()
        let stdDeviation = model.stdDeviation
        let variance = stdDeviation * stdDeviation
        let weights = particles.map { particle in
            observations.reduce(1.0) { probability, observation in
                let landmark = observation.landmark
                let value = particle.location.distance(to: landmark.location)
                let delta = abs(value - observation.measurement)
                let cdf = cdf.evaluate(mean: 0.0, variance: variance, value: delta)
                return probability * (1.0 - cdf)
            }
        }
        let epsilon = 0.000001
        let totalWeight = weights.reduce(0.0) { $0 + $1 } + epsilon
        let weighted: ParticleBuffer = Swift.zip(particles, weights).map { particle, weight in
            particle.with(weight: weight / totalWeight)
        }
    
        return weighted
    }
}
