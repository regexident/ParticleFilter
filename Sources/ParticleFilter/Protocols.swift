import Foundation

import Surge

import BayesFilter

public enum ParticleFilterEvaluation {
    case healthy
    case impoverished
}

public struct ParticleFilterEstimate {
    public let mean: Vector<Double>
    public let variance: Vector<Double>
}

public struct ParticleFilterOutput {
    public let state: ParticleFilterEstimate
    public let particles: [Particle]
}

public protocol ParticleFilterProtocol: BayesFilter {
    associatedtype Particles: Collection where Particles.Element == Particle

    var particles: Particles { get }
    var model: Model { get }
}

internal protocol ParticlePredictorProtocol {
    associatedtype ParticleBuffer
    
    func predict(
        particles: ParticleBuffer,
        control: Particle.Location,
        model: MotionModel
    ) -> ParticleBuffer
}

internal protocol ParticleWeighterProtocol {
    associatedtype ParticleBuffer
    
    func weight(
        particles: ParticleBuffer,
        observations: [LandmarkObservation<Double>],
        model: ObservationModel
    ) -> ParticleBuffer
}

internal protocol ParticleEvaluatorProtocol {
    associatedtype ParticleBuffer
    
    func evaluate(
        particles: ParticleBuffer,
        model: EvaluationModel
    ) -> ParticleFilterEvaluation
}

internal protocol ParticleResamplerProtocol {
    associatedtype ParticleBuffer
    
    func resample(
        particles: ParticleBuffer
    ) -> ParticleBuffer
}

internal protocol ParticleEstimatorProtocol {
    associatedtype ParticleBuffer
    
    func estimate(
        particles: ParticleBuffer
    ) -> ParticleFilterEstimate
}
