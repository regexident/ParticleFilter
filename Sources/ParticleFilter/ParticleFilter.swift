public class StatefulParticleFilter<T: ParticleFilterProtocol> {
    private let particleFilter: T
    
    public var model: Model
    
    public private(set) var estimate: ParticleFilterEstimate? = nil
    public private(set) var particles: [Particle]
    
    public init(
        particleFilter: T,
        model: Model,
        particles: [Particle]
    ) {
        self.particleFilter = particleFilter
        self.model = model
        self.particles = particles
    }
    
    public func filter(
        observations: [Observation],
        control: Particle.Vector
    ) -> ParticleFilterOutput {
        let output = self.particleFilter.filter(
            particles: self.particles,
            observations: observations,
            model: self.model,
            control: control
        )
        
        self.estimate = output.estimate
        self.particles = output.particles
        
        return output
    }
}

extension StatefulParticleFilter: ParticleFilterProtocol {
    public func filter(
        particles: [Particle],
        observations: [Observation],
        model: Model,
        control: Particle.Vector
    ) -> ParticleFilterOutput {
        return self.particleFilter.filter(
            particles: particles,
            observations: observations,
            model: model,
            control: control
        )
    }
}
