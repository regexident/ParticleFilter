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

    public func predict(
        particles: [Particle],
        control: Particle.Vector,
        model: MotionModel
    ) -> [Particle] {
        let impl: ParticleFilterProtocol = self.gpu ?? self.cpu

        return impl.predict(
            particles: particles,
            control: control,
            model: model
        )
    }

    public func weight(
        particles: [Particle],
        observations: [Observation],
        model: ObservationModel
    ) -> [Particle] {
        let impl: ParticleFilterProtocol = self.gpu ?? self.cpu

        return impl.weight(
            particles: particles,
            observations: observations,
            model: model
        )
    }

    public func evaluate(
        particles: [Particle],
        model: EvaluationModel
    ) -> Bool {
        let impl: ParticleFilterProtocol = self.gpu ?? self.cpu

        return impl.evaluate(
            particles: particles,
            model: model
        )
    }

    public func resample(
        particles: [Particle]
    ) -> [Particle] {
        let impl: ParticleFilterProtocol = self.gpu ?? self.cpu

        return impl.resample(particles: particles)
    }

    public func estimate(
        particles: [Particle]
    ) -> Particle.Vector {
        let impl: ParticleFilterProtocol = self.gpu ?? self.cpu

        return impl.estimate(
            particles: particles
        )
    }

    public func variance(
        particles: [Particle],
        mean: Particle.Vector
    ) -> Double {
        let impl: ParticleFilterProtocol = self.gpu ?? self.cpu

        return impl.variance(
            particles: particles,
            mean: mean
        )
    }
}
