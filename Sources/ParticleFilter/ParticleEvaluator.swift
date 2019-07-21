import Foundation

import Surge

internal struct ParticleEvaluator: ParticleEvaluatorProtocol {
    internal typealias ParticleBuffer = [Particle]
    
    internal func evaluate(
        particles: ParticleBuffer,
        model: EvaluationModel
    ) -> ParticleFilterEvaluation {
        assert(!particles.isEmpty)
        
        // Neff according to Kong et al. (1994):
        
        var totalWeights = 0.0
        var totalSquaredWeights = 0.0
        for particle in particles {
            let weight = particle.weight
            totalWeights += weight
            totalSquaredWeights += weight * weight
        }
        let totalWeightsSquared = totalWeights * totalWeights
        
        let epsilon = 0.000001
        
        let neff = totalWeightsSquared / (totalSquaredWeights + epsilon)
        let normalizedNeff = neff / Double(particles.count)
        
        let evaluation: ParticleFilterEvaluation
        if normalizedNeff > model.threshold {
            evaluation = .healthy
        } else {
            evaluation = .impoverished
        }
        
        return evaluation
    }
}
