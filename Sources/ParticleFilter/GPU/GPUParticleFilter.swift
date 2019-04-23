import Darwin

public class GPUParticleFilter {
    public init() {
        // nothing
    }
}

extension GPUParticleFilter: ParticleFilterProtocol {
    public func filter(
        particles: [Particle],
        observations: [Observation],
        model: Model,
        control: Particle.Vector
    ) -> ParticleFilterOutput {
        fatalError("Unimplemented: \(type(of: self)).\(#function)")
    }
    
    public func predict(
        particles: [Particle],
        control: Particle.Vector,
        model: MotionModel
    ) -> [Particle] {
        fatalError("Unimplemented: \(type(of: self)).\(#function)")
    }
    
    public func weight(
        particles: [Particle],
        observations: [Observation],
        model: ObservationModel
    ) -> [Particle] {
        fatalError("Unimplemented: \(type(of: self)).\(#function)")
    }
    
    public func evaluate(
        particles: [Particle],
        model: EvaluationModel
    ) -> Bool {
        fatalError("Unimplemented: \(type(of: self)).\(#function)")
    }
    
    public func resample(particles: [Particle]) -> [Particle] {
        fatalError("Unimplemented: \(type(of: self)).\(#function)")
    }
    
    public func estimate(
        particles: [Particle]
    ) -> Particle.Vector {
        fatalError("Unimplemented: \(type(of: self)).\(#function)")
    }
    
    public func variance(
        particles: [Particle],
        mean: Particle.Vector
    ) -> Double {
        fatalError("Unimplemented: \(type(of: self)).\(#function)")
    }
    
    // normal cumulative distribution function:
    internal func cdf(
        mean: Double,
        variance: Double,
        value: Double
    ) -> Double {
        fatalError("Unimplemented: \(type(of: self)).\(#function)")
    }
}
