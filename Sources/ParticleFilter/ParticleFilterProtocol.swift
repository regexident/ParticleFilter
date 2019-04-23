import Foundation

import particle_filter

public struct ParticleFilterOutput {
    let estimate: Double3
    let particles: [Particle]
    let variance: Double
}

public protocol ParticleFilterProtocol {
    func filter(
        particles: [Particle],
        observations: [Observation],
        model: Model,
        control: Double3
    ) -> ParticleFilterOutput
    
    func predict(
        particles: [Particle],
        control: Double3,
        model: MotionModel
    ) -> [Particle]
    
    func weight(
        particles: [Particle],
        observations: [Observation],
        model: ObservationModel
    ) -> [Particle]
    
    func evaluate(
        particles: [Particle],
        model: EvaluationModel
    ) -> Bool
    
    func resample(
        particles: [Particle]
    ) -> [Particle]
    
    func estimate(
        particles: [Particle]
    ) -> Double3
    
    func variance(
        particles: [Particle],
        mean: Double3
    ) -> Double
}
