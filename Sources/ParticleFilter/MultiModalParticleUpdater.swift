import Foundation

import Surge
import BayesFilter
import StateSpace
import StateSpaceModel

// swiftlint:disable all identifier_name

public typealias StatefulMultiModalParticleUpdater<Model: Hashable, ObservationModel> = Estimateful<MultiModalParticleUpdater<Model, ObservationModel>>

public class MultiModalParticleUpdater<Model, ObservationModel>
    where Model: Hashable
{
    public var observationNoise: Vector<Double>
    public var threshold: Double

    public var observationModels: [Model: ObservationModel] = [:]
    private var generator: AnyRandomNumberGenerator
    public var closure: (Model) -> ObservationModel

    public convenience init(
        observationNoise: Vector<Double>,
        threshold: Double,
        closure: @escaping (Model) -> ObservationModel
    ) {
        let generator = SystemRandomNumberGenerator()
        self.init(
            observationNoise: observationNoise,
            threshold: threshold,
            generator: generator,
            closure: closure
        )
    }

    public init<T>(
        observationNoise: Vector<Double>,
        threshold: Double,
        generator: T,
        closure: @escaping (Model) -> ObservationModel
    )
    where
        T: RandomNumberGenerator
    {
        self.observationNoise = observationNoise
        self.threshold = threshold
        self.generator = AnyRandomNumberGenerator(generator)
        self.closure = closure
    }

    private func withObservationModel<T>(
        for model: Model,
        _ closure: (ObservationModel) -> T
    ) -> T {
        let observationModel = self.observationModels[model] ?? self.closure(model)
        let result = closure(observationModel)
        self.observationModels[model] = observationModel
        return result
    }
}

extension MultiModalParticleUpdater
    where ObservationModel: ParticleObservationModel
{
    internal static func weight<S>(
        states: [Vector<Double>],
        observations: S,
        observationNoise: Vector<Double>,
        particleObservation: (State, Model) -> Vector<Double>
    ) -> [Double]
        where S : Sequence, S.Element == Observation
    {
        assert(!states.isEmpty)
        let cdf = NormalCumulativeDistributionFunction()
        let observationVariances = pow(observationNoise, 2.0)
        var totalWeight: Double = 0.000001 // non-zero to avoid divide by zero
        let weights: [Double] = states.map { state in
            let weight = observations.reduce(1.0) { probability, observation in
                let modelObservation = observation.value
                let particleObservation = particleObservation(state, observation.model)
                let observationErrors = modelObservation - particleObservation
                let absoluteObservationErrors = Vector(abs(observationErrors.scalars))
                let partialProbabilities = Swift.zip(observationVariances, absoluteObservationErrors).map { variance, error in
                    1.0 - cdf.evaluate(mean: 0.0, variance: variance, value: error)
                }
                return partialProbabilities.reduce(probability, *)
            }
            totalWeight += weight
            return weight
        }
        let normalizedWeights = weights.map { $0 / totalWeight }
        return normalizedWeights
    }

    internal static func shouldResample(
        weights: [Double],
        threshold: Double
    ) -> Bool {
        assert(!weights.isEmpty)

        // Neff according to Kong et al. (1994):

        var totalWeights = 0.0
        var totalSquaredWeights = 0.0
        for weight in weights {
            totalWeights += weight
            totalSquaredWeights += weight * weight
        }
        let totalWeightsSquared = totalWeights * totalWeights

        let epsilon = 0.000001

        let neff = totalWeightsSquared / (totalSquaredWeights + epsilon)
        let normalizedNeff = neff / Double(weights.count)

        if normalizedNeff > threshold {
            return true
        } else {
            return false
        }
    }

//    internal static func resample(estimate: Estimate) -> Estimate {
//        var generator = SystemRandomNumberGenerator()
//        return self.resample(estimate: estimate, using: &generator)
//    }

    internal static func resample<T>(
        estimate: Estimate,
        using generator: inout T
    ) -> Estimate
        where T: RandomNumberGenerator
    {
        assert(!estimate.isEmpty)

        // Implementation of Stochastic Universal Sampling:

        var generator = generator

        var states: [Vector<Double>] = []
        var weights: [Double] = []

        let n = estimate.count
        let weight = 1.0 / Double(n)
        let totalWeight = estimate.weights.reduce(0.0, +)
        let stride = totalWeight / Double(n)

        let offset = Double.random(in: 0.0...stride, using: &generator)
        var cursor = -offset

        var index = -1

        for i in 0..<n {
            let sample = Double(i) * stride

            while (cursor <= sample) && (index + 1 < n) {
                index += 1
                cursor += estimate.weights[index]
            }

            states.append(estimate.states[index])
            weights.append(weight)
        }

        return Estimate(
            states: states,
            weights: weights
        )
    }
}

extension MultiModalParticleUpdater: DimensionsValidatable {
    public func validate(for dimensions: DimensionsProtocol) throws {
        for observationModel in self.observationModels.values {
            if let observationModel = observationModel as? DimensionsValidatable {
                try observationModel.validate(for: dimensions)
            }
        }
    }
}

extension MultiModalParticleUpdater: Statable {
    public typealias State = Vector<Double>
}

extension MultiModalParticleUpdater: Observable {
    public typealias Observation = MultiModal<Model, Vector<Double>>
}

extension MultiModalParticleUpdater: Estimatable {
    public typealias Estimate = ParticleEstimate
}

extension MultiModalParticleUpdater: BayesUpdaterProtocol, ParticleUpdaterProtocol
    where ObservationModel: ParticleObservationModel
{
    public func updated(
        prediction: Estimate,
        observation: Observation
    ) -> Estimate {
        let observations = CollectionOfOne(observation)
        return self.batchUpdated(
            prediction: prediction,
            observations: observations
        )
    }

    public func batchUpdated<S>(
        prediction: ParticleEstimate,
        observations: S
    ) -> ParticleEstimate
        where S : Sequence, S.Element == Observation
    {
        let states = prediction.states

        assert(!states.isEmpty)

        // Calculate normalized weights based on observation model:
        let weights = type(of: self).weight(
            states: states,
            observations: observations,
            observationNoise: self.observationNoise
        ) { state, model in
            self.withObservationModel(for: model) { model in
                model.apply(state: state)
            }
        }

        // Check if resampling is necessary due to depletion/impoverishment:
        let shouldResample = type(of: self).shouldResample(
            weights: weights,
            threshold: self.threshold
        )

        let estimate = Estimate(states: states, weights: weights)

        guard shouldResample else {
            return estimate
        }

        // Resample particles if particle set has been depleted/impoverished:
        let resampled = Self.resample(
            estimate: estimate,
            using: &self.generator
        )

        return resampled
    }
}
