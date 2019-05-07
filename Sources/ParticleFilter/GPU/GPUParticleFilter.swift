import Darwin

public class GPUParticleFilter {
    public weak var delegate: ParticleFilterDelegate? = nil
    
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
}
