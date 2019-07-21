import Foundation

import BayesFilter

public class ParticleFilter: ParticleFilterProtocol {
    public typealias Observation = [LandmarkObservation<Double>]
    public typealias Control = Particle.Location
    public typealias Estimate = [Particle]

    public typealias ParticleBuffer = [Particle]
    public typealias ObservationBuffer = [Observation]

    public var model: Model

    public private(set) var estimate: ParticleFilterEstimate? = nil
    public private(set) var particles: ParticleBuffer

    public init(
        model: Model,
        particles: ParticleBuffer
    ) {
        assert(!particles.isEmpty)

        self.model = model
        self.particles = particles
    }

    public func predict(
        control: Control
    ) -> Estimate {
        // Predict particle movement based on motion model:
        let predictor = ParticlePredictor()

        return predictor.predict(
            particles: self.particles,
            control: control,
            model: self.model.motion
        )
    }

    public func update(
        prediction: Estimate,
        observation: Observation,
        control: Control
    ) -> Estimate {
        assert(!prediction.isEmpty)

        var particles = prediction
        let model = self.model

        // Calculate normalized weights based on observation model:
        let weighter = ParticleWeighter()
        particles = weighter.weight(
            particles: particles,
            observations: observation,
            model: model.observation
        )

        // Check if resampling is necessary due to depletion/impoverishment:
        let evaluator = ParticleEvaluator()
        let evaluation = evaluator.evaluate(
            particles: particles,
            model: model.evaluation
        )

        // Resample particles if particle set has been depleted/impoverished:
        let resampler = ParticleResampler()
        if evaluation == .impoverished {
            particles = resampler.resample(
                particles: particles
            )
        }

        self.particles = particles

        return particles
    }
}
