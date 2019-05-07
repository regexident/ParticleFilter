public struct ParticleFilter {
    private let cpu: CPUParticleFilter
    private let gpu: GPUParticleFilter? = nil

    public init() {
        self.cpu = CPUParticleFilter()
    }
}

extension ParticleFilter: ParticleFilterProtocol {
    public func filter(
        particles: [Particle],
        observations: [Observation],
        model: Model,
        control: Particle.Vector
    ) -> ParticleFilterOutput {
        let impl: ParticleFilterProtocol = self.gpu ?? self.cpu

        return impl.filter(
            particles: particles,
            observations: observations,
            model: model,
            control: control
        )
    }
}
